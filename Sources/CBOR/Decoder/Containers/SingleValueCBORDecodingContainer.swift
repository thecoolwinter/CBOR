//
//  SingleValueCBORDecodingContainer.swift
//  CBOR
//
//  Created by Khan Winter on 8/20/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct SingleValueCBORDecodingContainer: DecodingContextContainer {
    let context: DecodingContext
    let data: DataRegion
}

extension SingleValueCBORDecodingContainer: Decoder {
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        try KeyedDecodingContainer(KeyedCBORDecodingContainer(context: context, data: data))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        try UnkeyedCBORDecodingContainer(context: context, data: data)
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        self
    }
}

extension SingleValueCBORDecodingContainer: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        data.isNil()
    }

    func decode(_: Bool.Type) throws -> Bool {
        let argument = try checkType(.simple, arguments: 20, 21, as: Bool.self)
        return argument == 21
    }

    func decode(_: Float.Type) throws -> Float {
        let arg = try checkType(.simple, arguments: 25, 26, as: Float.self)
        if arg == 25 {
            let floatRaw = try data.read(as: UInt16.self)
            guard let value = Float(halfPrecision: floatRaw) else {
                throw DecodingError.dataCorrupted(
                    context.error("Could not decode half-precision float into Swift Float.")
                )
            }
            return value
        }

        let floatRaw = try data.read(as: UInt32.self)
        return Float(bitPattern: floatRaw)
    }

    func decode(_: Double.Type) throws -> Double {
        try checkType(.simple, arguments: 27, as: Double.self)
        let doubleRaw = try data.read(as: UInt64.self).littleEndian
        return Double(bitPattern: doubleRaw)
    }

    func decode<T: Decodable & FixedWidthInteger>(_: T.Type) throws -> T {
        try checkType(.uint, .nint, forType: T.self)
        let value = try data.readInt(as: T.self)
        if data.type == .nint {
            guard T.min < 0 else {
                throw DecodingError.typeMismatch(
                    Int.self,
                    context.error("Found a negative integer while attempting to decode an unsigned int \(T.self).")
                )
            }
            return -1 - value
        }
        return value
    }

    func decode(_: String.Type) throws -> String {
        try checkType(.string, forType: String.self)

        if data.argument == Constants.indeterminateArg {
            return try decodeIndeterminateString()
        }

        let length = data.count
        if length == 0 {
            return ""
        }

        guard data.canRead(length) else {
            throw DecodingError.valueNotFound(Bool.self, context.error("Unexpected end of data"))
        }
        let bytes = data[0..<length]
        guard let string = String(data: Data(bytes), encoding: .utf8) else {
            throw DecodingError.dataCorrupted(context.error("Failed to decode valid UTF8 string."))
        }
        return string
    }

    private func decodeIndeterminateString() throws -> String {
        // Collect strings until we're done
        var idx = 0
        var string = ""
        while idx < data.count && data[idx] != Constants.breakCode {
            let slice = data[(idx + 1)..<data.count]
            let argument = data[idx] & 0b11111
            let size = try slice.readInt(as: Int.self, argument: argument)

            idx += 1

            guard let byteCount = argument.byteCount() else {
                throw ScanError.invalidSize(byte: argument, offset: data.globalIndex)
            }

            let utf8Start = idx + Int(byteCount)
            let utf8Slice = data[utf8Start..<(utf8Start + size)]

            guard let substring = String(data: Data(utf8Slice), encoding: .utf8) else {
                throw DecodingError.dataCorrupted(
                    context.error("Failed to decode UTF8 string in \(utf8Start..<(utf8Start + size))")
                )
            }

            string += substring
            idx = utf8Start + size
        }
        return string
    }

    // Attempt first to decode a tagged date value, then move on and try decoding any of the following as a date:
    // - Int
    // - Float/Double/Float16
    // - ISO String
    private func _decode(_: Date.Type) throws -> Date {
        if let argument = try? checkType(.tagged, arguments: 0, 1, as: Date.self) {
            let taggedData = context.results.loadTagData(tagMapIndex: data.mapOffset)
            if argument == 0 {
                // String
                return try decodeStringDate(data: taggedData)
            } else {
                return try decodeEpochDate(data: taggedData)
            }
        }

        let region = context.results.load(at: data.mapOffset)
        guard let date = (try? decodeStringDate(data: region)) ?? (try? decodeEpochDate(data: region)) else {
            throw DecodingError.typeMismatch(Date.self, context.error("Failed to decode a valid `Date` value."))
        }
        return date
    }

    private func decodeStringDate(data: DataRegion) throws -> Date {
        let string = try SingleValueCBORDecodingContainer(context: context, data: data).decode(String.self)
#if canImport(FoundationEssentials)
        guard let date = try? Date.ISO8601FormatStyle().parse(string) else {
            throw DecodingError.dataCorrupted(context.error("Failed to decode date from \"\(string)\""))
        }
#else
        guard let date = ISO8601DateFormatter().date(from: string) else {
            throw DecodingError.dataCorrupted(context.error("Failed to decode date from \"\(string)\""))
        }
#endif
        return date
    }

    private func decodeEpochDate(data: DataRegion) throws -> Date {
        // Epoch Timestamp, can be a floating point or positive/negative integer value
        switch (data.type, data.argument) {
        case (.uint, _):
            let int = try data.readInt(as: Int.self)
            return Date(timeIntervalSince1970: Double(int))
        case (.nint, _):
            let int = -1 - (try data.readInt(as: Int.self))
            return Date(timeIntervalSince1970: Double(int))
        case (.simple, 25), (.simple, 26):
            // Float
            let float = try SingleValueCBORDecodingContainer(context: context, data: data).decode(Float.self)
            return Date(timeIntervalSince1970: Double(float))
        case (.simple, 27):
            // Double
            let double = try SingleValueCBORDecodingContainer(context: context, data: data).decode(Double.self)
            return Date(timeIntervalSince1970: double)
        default:
            throw DecodingError.typeMismatch(
                Date.self,
                context.error("Invalid type found for epoch date: \(data.type) at \(data.globalIndex)")
            )
        }
    }

    private func _decode(_: Data.Type) throws -> Data {
        try checkType(.bytes, forType: Data.self)

        if data.argument == Constants.indeterminateArg {
            return try decodeIndeterminateData()
        }

        let length = data.count
        if length == 0 {
            return Data()
        }

        guard data.canRead(length) else {
            throw DecodingError.valueNotFound(Bool.self, context.error("Unexpected end of data"))
        }
        let bytes = data[0..<length]
        return Data(bytes)
    }

    private func decodeIndeterminateData() throws -> Data {
        // Collect strings until we're done
        var idx = 0
        var string = Data()
        while idx < data.count && data[idx] != Constants.breakCode {
            let slice = data[(idx + 1)..<data.count]
            let argument = data[idx] & 0b11111
            let size = try slice.readInt(as: Int.self, argument: argument)

            idx += 1

            guard let byteCount = argument.byteCount() else {
                throw ScanError.invalidSize(byte: argument, offset: data.globalIndex)
            }

            let substringStart = idx + Int(byteCount)
            let substringSlice = data[substringStart..<(substringStart + size)]

            let substring = Data(substringSlice)
            string += substring
            idx = substringStart + size
        }
        return string
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        // Unfortunate force unwraps here, but necessary
        // swiftlint:disable force_cast
        if T.self == Date.self {
            return try _decode(Date.self) as! T
        } else if T.self == Data.self {
            return try _decode(Data.self) as! T
        } else if let TaggedType = T.self as? TaggedCBORItem.Type {
            try checkType(.tagged, forType: T.self)
            try checkTag(TaggedType.tag, forType: T.self)
            let taggedData = context.results.loadTagData(tagMapIndex: data.mapOffset)
            return try TaggedType.init(
                decodeTaggedDataUsing: SingleValueCBORDecodingContainer(context: context, data: taggedData)
            ) as! T
        } else {
            return try T(from: self)
        }
        // swiftlint:enable force_cast
    }
}
