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

@usableFromInline
enum ScanError: Error {
    case unexpectedEndOfData
    case invalidMajorType(byte: UInt8, offset: Int)
    case invalidSize(byte: UInt8, offset: Int)
    case expectedMajorType(offset: Int)
    case typeInIndeterminateString(type: MajorType, offset: Int)
    case rejectedIndeterminateLength(type: MajorType, offset: Int)
    case cannotRepresentInt(max: UInt, found: UInt, offset: Int)
    case noTagInformation(tag: UInt, offset: Int)
    case invalidMajorTypeForTaggedItem(tag: UInt, expected: Set<MajorType>, found: MajorType, offset: Int)
}

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
            let idx = reader.index
            try scanNext()
            assert(idx < reader.index, "Scanner made no forward progress in scan")
        }
        return results
    }

    private mutating func scanNext() throws {
        guard let type = reader.peekType(), let raw = reader.peek() else {
            if reader.isEmpty {
                throw ScanError.unexpectedEndOfData
            } else {
                throw ScanError.invalidMajorType(byte: (reader.pop() & 0b1110_0000) >> 5, offset: reader.index - 1)
            }
        }

        try scanType(type: type, raw: raw)
    }

    private mutating func scanType(type: MajorType, raw: UInt8) throws {
        switch type {
        case .uint, .nint:
            try scanInt(raw: raw)
        case .bytes:
            try scanBytesOrString(.bytes, raw: raw)
        case .string:
            try scanBytesOrString(.string, raw: raw)
        case .array:
            try scanArray()
        case .map:
            try scanMap()
        case .simple:
            try scanSimple(raw: raw)
        case .tagged:
            try scanTagged(raw: raw)
        }
    }

    // MARK: - Scan Int

    private mutating func scanInt(raw: UInt8) throws {
        let size = try popByteCount()
        let offset = reader.index
        results.recordType(raw, currentByteIndex: offset, length: size)
        guard reader.canRead(size) else { throw ScanError.unexpectedEndOfData }
        reader.pop(size)
    }

    // MARK: - Scan Simple

    private mutating func scanSimple(raw: UInt8) throws {
        let idx = reader.index
        results.recordSimple(reader.pop(), currentByteIndex: idx)
        guard reader.canRead(raw.simpleLength()) else {
            throw ScanError.unexpectedEndOfData
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

        if (type == .string || type == .bytes) && options.rejectIndeterminateLengths {
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

    private mutating func scanArray() throws {
        guard peekIsIndeterminate() else {
            let size = try reader.readNextInt(as: Int.self)
            let mapIdx = results.recordArrayStart(currentByteIndex: reader.index)
            for _ in 0..<size {
                try scanNext()
            }
            results.recordEnd(childCount: size, resultLocation: mapIdx, currentByteIndex: reader.index)
            return
        }

        if options.rejectIndeterminateLengths {
            throw ScanError.rejectedIndeterminateLength(type: .array, offset: reader.index)
        }

        let mapIdx = results.recordArrayStart(currentByteIndex: reader.index)
        reader.pop() // Pop type
        var count = 0
        while reader.peek() != Constants.breakCode {
            try scanNext()
            count += 1
        }
        // Pop the break byte
        reader.pop()
        results.recordEnd(childCount: count, resultLocation: mapIdx, currentByteIndex: reader.index)
    }

    // MARK: - Scan Map

    private mutating func scanMap() throws {
        guard peekIsIndeterminate() else {
            let keyCount = try reader.readNextInt(as: Int.self)
            guard keyCount < Int.max / 2 else {
                throw ScanError.cannotRepresentInt(max: UInt(Int.max), found: UInt(keyCount) * 2, offset: reader.index)
            }

            let size = keyCount * 2
            let mapIdx = results.recordMapStart(currentByteIndex: reader.index)
            for _ in 0..<size {
                try scanNext()
            }
            results.recordEnd(childCount: size, resultLocation: mapIdx, currentByteIndex: reader.index)
            return
        }

        if options.rejectIndeterminateLengths {
            throw ScanError.rejectedIndeterminateLength(type: .map, offset: reader.index)
        }

        let mapIdx = results.recordMapStart(currentByteIndex: reader.index)
        reader.pop() // Pop type
        var count = 0
        while reader.peek() != Constants.breakCode {
            try scanNext() // Maps should always have a multiple of two values.
            try scanNext()
            count += 2
        }
        // Pop the break byte
        reader.pop()
        results.recordEnd(childCount: count, resultLocation: mapIdx, currentByteIndex: reader.index)
    }

    // MARK: - Scan Tagged

    private mutating func scanTagged(raw: UInt8) throws {
        // Scan the tag number (passing the raw value here makes it record a Tag rather than an Int)
        try scanInt(raw: raw)

        guard let nextRaw = reader.peek(), let nextTag = MajorType(rawValue: nextRaw) else {
            throw ScanError.unexpectedEndOfData
        }

        try scanType(type: nextTag, raw: nextRaw)
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
}
