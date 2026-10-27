//
//  MajorType.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

/// Represents a major type as described by the CBOR specification.
@frozen
public enum MajorType: UInt8, Sendable, Hashable, Equatable {
    case uint = 0
    case nint = 1
    case bytes = 2
    case string = 3
    case array = 4
    case map = 5
    case tagged = 6
    case simple = 7

    /// Create a major type using a raw integer (only uses the highest 3 bits).
    @inline(__always)
    public init?(rawValue: UInt8) {
        // We only care about the top 3 bits
        switch rawValue >> 5 {
        case MajorType.uint.rawValue: self = .uint
        case MajorType.nint.rawValue: self = .nint
        case MajorType.bytes.rawValue: self = .bytes
        case MajorType.string.rawValue: self = .string
        case MajorType.array.rawValue: self = .array
        case MajorType.map.rawValue: self = .map
        case MajorType.tagged.rawValue: self = .tagged
        case MajorType.simple.rawValue: self = .simple
        default: return nil
        }
    }

    @inline(__always)
    var bits: UInt8 {
        rawValue << 5
    }

    @inline(__always)
    var intValue: Int {
        Int(bits)
    }
}
