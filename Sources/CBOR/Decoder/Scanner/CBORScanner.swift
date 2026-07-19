//
//  CBORScanner.swift
//  CBOR
//
//  Created by Khan Winter on 8/24/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// # Why Scan?
/// I'd have loved to use a 'pop' method for decoding, where we only decode as data is requested. However, the way
/// Swift's decoding APIs work forces us to be able to be able to do random access for keys in maps, which requires
/// scanning.
///
/// Here we build a map of byte offsets and types to be able to quickly scan through a CBOR blob to find specific
/// indices and keys.
///
/// # Dev Notes
///
/// - This is where we do any indeterminate length validation and rejection. The decoder containers themselves will
///   take either indeterminate or specific lengths and decode them.
@usableFromInline
struct CBORScanner {
    private var reader: DataReader
    private var results: Results
    private let options: DecodingOptions

    init(data: DataReader, options: DecodingOptions = DecodingOptions()) {
        self.reader = data
        self.results = Results(dataCount: data.count, reader: reader)
        self.options = options
    }

    // MARK: - Scan

    consuming func scan() throws -> Results {
        while !reader.isEmpty {
            if options.singleTopLevelItem && reader.index > 0 {
                throw ScanError.unreadDataAfterEnd
            }

            let idx = reader.index
            try scanNext(depth: 0)
            assert(idx < reader.index, "Scanner made no forward progress in scan")
        }

        if options.singleTopLevelItem && !reader.isEmpty {
            throw ScanError.unreadDataAfterEnd
        }

        return results
    }

    private mutating func scanNext(depth: Int) throws {
        guard let type = reader.peekType(), let raw = reader.peek() else {
            if reader.isEmpty {
                throw ScanError.unexpectedEndOfData
            } else {
                throw ScanError.invalidMajorType(byte: (reader.pop() & 0b1110_0000) >> 5, offset: reader.index - 1)
            }
        }

        guard depth < options.recursionDepth else {
            throw ScanError.recursionLimit
        }

        try scanType(type: type, raw: raw, depth: depth)
    }

    private mutating func scanType(type: MajorType, raw: UInt8, depth: Int) throws {
        switch type {
        case .uint, .nint:
            try scanInt(raw: raw)
        case .bytes:
            try scanBytesOrString(.bytes, raw: raw)
        case .string:
            try scanBytesOrString(.string, raw: raw)
        case .array:
            try scanArray(depth: depth)
        case .map:
            try scanMap(depth: depth)
        case .simple:
            try scanSimple(raw: raw)
        case .tagged:
            try scanTagged(raw: raw, depth: depth)
        }
    }

    // MARK: - Scan Int

    private mutating func scanInt(raw: UInt8) throws {
        let size = try popByteCount()
        let offset = reader.index
        results.recordType(raw, currentByteIndex: offset, length: size)
        guard reader.canRead(size) else { throw ScanError.unexpectedEndOfData }
        if options.rejectNonCanonical {
            // Validate the argument width even when the eventual Decodable type
            // ignores this value. DataRegion performs the same check on consumed
            // integers, but canonical validation must cover the complete object.
            _ = try reader.slice(offset..<(offset + size)).readInt(
                as: UInt64.self,
                argument: raw & 0b0001_1111
            )
        }
        reader.pop(size)
    }

    // MARK: - Scan Simple

    private mutating func scanSimple(raw: UInt8) throws {
        guard !(options.rejectUndefined && reader.peekArgument() == 23) else {
            throw ScanError.rejectedUndefined
        }

        let idx = reader.index
        results.recordSimple(reader.pop(), currentByteIndex: idx)
        guard reader.canRead(raw.simpleLength()) else {
            throw ScanError.unexpectedEndOfData
        }
        if options.rejectNonCanonical {
            try validatePreferredSimple(raw: raw, offset: idx)
        }
        reader.pop(raw.simpleLength())
    }

    // MARK: - Scan String/Bytes

    private mutating func scanBytesOrString(_ type: MajorType, raw: UInt8) throws {
        guard peekIsIndeterminate() else {
            let size = try reader.readNextInt(as: Int.self)
            let offset = reader.index
            results.recordType(raw, currentByteIndex: offset, length: size)
            guard reader.canRead(size) else { throw ScanError.unexpectedEndOfData }
            reader.pop(size)
            return
        }

        if (type == .string || type == .bytes)
            && (options.rejectIndeterminateLengths || options.rejectNonCanonical) {
            throw ScanError.rejectedIndeterminateLength(type: type, offset: reader.index)
        }

        reader.pop() // Pop type
        let start = reader.index
        // Indeterminate size, loop through real-sized strings until we find the break code.
        while reader.peek() != Constants.breakCode {
            guard let nextType = reader.peekType() else {
                throw ScanError.expectedMajorType(offset: reader.index)
            }
            guard nextType == type else {
                throw ScanError.typeInIndeterminateString(type: nextType, offset: reader.index)
            }

            let size = try reader.readNextInt(as: Int.self)
            guard reader.canRead(size) else { throw ScanError.unexpectedEndOfData }
            reader.pop(size) // Move to the next string
        }
        // Pop the break byte
        guard !reader.isEmpty else { throw ScanError.unexpectedEndOfData } // expected break byte (FF)
        reader.pop()
        results.recordType(raw, currentByteIndex: start, length: reader.index - start)
    }

    // MARK: - Scan Array

    private mutating func scanArray(depth: Int) throws {
        guard peekIsIndeterminate() else {
            let size = try reader.readNextInt(as: Int.self)
            let mapIdx = results.recordArrayStart(currentByteIndex: reader.index)
            for _ in 0..<size {
                try scanNext(depth: depth + 1)
            }
            results.recordEnd(childCount: size, resultLocation: mapIdx, currentByteIndex: reader.index)
            return
        }

        if options.rejectIndeterminateLengths || options.rejectNonCanonical {
            throw ScanError.rejectedIndeterminateLength(type: .array, offset: reader.index)
        }

        let mapIdx = results.recordArrayStart(currentByteIndex: reader.index)
        reader.pop() // Pop type
        var count = 0
        while reader.peek() != Constants.breakCode {
            try scanNext(depth: depth + 1)
            count += 1
        }
        // Pop the break byte
        reader.pop()
        results.recordEnd(childCount: count, resultLocation: mapIdx, currentByteIndex: reader.index)
    }

    // MARK: - Scan Map

    private mutating func scanMap(depth: Int) throws {
        guard peekIsIndeterminate() else {
            let keyCount = try reader.readNextInt(as: Int.self)
            guard keyCount < Int.max / 2 else {
                throw ScanError.cannotRepresentInt(max: UInt(Int.max), found: UInt(keyCount) * 2, offset: reader.index)
            }

            let mapIdx = results.recordMapStart(currentByteIndex: reader.index)
            var previousKey: Range<Int>?
            for _ in 0..<keyCount {
                let keyStart = reader.index
                try scanNext(depth: depth + 1)
                let keyRange = keyStart..<reader.index
                try validateMapKeyOrder(previous: previousKey, current: keyRange)
                previousKey = keyRange

                try scanNext(depth: depth + 1)
            }
            let size = keyCount * 2
            results.recordEnd(childCount: size, resultLocation: mapIdx, currentByteIndex: reader.index)
            return
        }

        if options.rejectIndeterminateLengths || options.rejectNonCanonical {
            throw ScanError.rejectedIndeterminateLength(type: .map, offset: reader.index)
        }

        let mapIdx = results.recordMapStart(currentByteIndex: reader.index)
        reader.pop() // Pop type
        var count = 0
        var previousKey: Range<Int>?
        while reader.peek() != Constants.breakCode {
            let keyStart = reader.index
            try scanNext(depth: depth + 1)
            let keyRange = keyStart..<reader.index
            try validateMapKeyOrder(previous: previousKey, current: keyRange)
            previousKey = keyRange

            try scanNext(depth: depth + 1)
            count += 2
        }
        // Pop the break byte
        reader.pop()
        results.recordEnd(childCount: count, resultLocation: mapIdx, currentByteIndex: reader.index)
    }

    // MARK: - Scan Tagged

    private mutating func scanTagged(raw: UInt8, depth: Int) throws {
        // Scan the tag number (passing the raw value here makes it record a Tag rather than an Int)
        try scanInt(raw: raw)

        guard let nextRaw = reader.peek(), let nextTag = MajorType(rawValue: nextRaw) else {
            throw ScanError.unexpectedEndOfData
        }

        try scanType(type: nextTag, raw: nextRaw, depth: depth)
    }
}

extension CBORScanner {
    private mutating func popByteCount() throws -> Int {
        let byteCount = reader.popArgument()
        return switch byteCount {
        case let value where value < Constants.maxArgSize: 0
        case 24: 1
        case 25: 2
        case 26: 4
        case 27: 8
        default:
            throw ScanError.invalidSize(byte: byteCount, offset: reader.index - 1)
        }
    }

    private func peekIsIndeterminate() -> Bool {
        (reader.peekArgument() ?? 0) == 0b1_1111
    }

    private func validateMapKeyOrder(previous: Range<Int>?, current: Range<Int>) throws {
        guard options.rejectUnorderedMap || options.rejectNonCanonical,
              let previous else {
            return
        }

        let comparison = reader.compareEncodedKeys(previous, current)
        guard comparison < 0 else {
            throw ScanError.nonCanonicalMapKey(
                offset: current.lowerBound,
                duplicate: comparison == 0
            )
        }
    }

    private func validatePreferredSimple(raw: UInt8, offset: Int) throws {
        let argument = raw & 0b0001_1111
        let payloadStart = reader.index

        switch argument {
        case 0...23:
            return
        case 24:
            let value = try reader.slice(payloadStart..<(payloadStart + 1)).read(as: UInt8.self)
            guard value >= 32 else { throw ScanError.nonCanonicalSimple(offset: offset) }
        case 25:
            let bits = try reader.slice(payloadStart..<(payloadStart + 2)).read(as: UInt16.self)
            if let value = Float(halfPrecision: bits), value.isNaN, bits != 0x7e00 {
                throw ScanError.nonCanonicalSimple(offset: offset)
            }
        case 26:
            let bits = try reader.slice(payloadStart..<(payloadStart + 4)).read(as: UInt32.self)
            let preferred = PreferredFloatOptimizer(value: Double(Float(bitPattern: bits)))
            guard preferred.argument == 26 else { throw ScanError.nonCanonicalSimple(offset: offset) }
        case 27:
            let bits = try reader.slice(payloadStart..<(payloadStart + 8)).read(as: UInt64.self)
            let preferred = PreferredFloatOptimizer(value: Double(bitPattern: bits))
            guard preferred.argument == 27 else { throw ScanError.nonCanonicalSimple(offset: offset) }
        default:
            throw ScanError.nonCanonicalSimple(offset: offset)
        }
    }
}
