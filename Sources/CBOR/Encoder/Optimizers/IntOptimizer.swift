//
//  IntOptimizer.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

@inlinable // swiftlint:disable:next cyclomatic_complexity
func IntOptimizer<IntType: FixedWidthInteger>(value: IntType) -> EncodingOptimizer {
    let encodingValue: UInt
    if value < 0 {
        encodingValue = UInt(-1 - value)
        return switch encodingValue {
        case let value where value < Constants.maxArgSize: SmallNegativeIntOptimizer(value: encodingValue)
        case let value where value <= UInt8.max: NegativeIntOptimizer(value: UInt8(encodingValue))
        case let value where value <= UInt16.max: NegativeIntOptimizer(value: UInt16(encodingValue))
        case let value where value <= UInt32.max: NegativeIntOptimizer(value: UInt32(encodingValue))
        default: NegativeIntOptimizer(value: encodingValue)
        }
    } else {
        encodingValue = UInt(value)
        return switch encodingValue {
        case let value where value < Constants.maxArgSize: SmallPositiveIntOptimizer(value: encodingValue)
        case let value where value <= UInt8.max: PositiveIntOptimizer(value: UInt8(encodingValue))
        case let value where value <= UInt16.max: PositiveIntOptimizer(value: UInt16(encodingValue))
        case let value where value <= UInt32.max: PositiveIntOptimizer(value: UInt32(encodingValue))
        default: PositiveIntOptimizer(value: encodingValue)
        }
    }
}

@usableFromInline
struct SmallPositiveIntOptimizer<IntType: FixedWidthInteger>: EncodingOptimizer {
    let value: UInt8

    @inline(__always)
    @usableFromInline var type: MajorType { .uint }
    @inline(__always)
    @usableFromInline var argument: UInt8 { value }
    @inline(__always)
    @usableFromInline var contentSize: Int { 0 }

    @usableFromInline
    init(value: IntType) {
        assert(value < Constants.maxArgSize)
        assert(value >= IntType.zero)
        self.value = UInt8(truncatingIfNeeded: value)
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) { }
}

@usableFromInline
struct SmallNegativeIntOptimizer<IntType: FixedWidthInteger>: EncodingOptimizer {
    let value: UInt8

    @inline(__always)
    @usableFromInline var type: MajorType { .nint }
    @inline(__always)
    @usableFromInline var argument: UInt8 { UInt8(value) }
    @inline(__always)
    @usableFromInline var contentSize: Int { 0 }

    @usableFromInline
    init(value: IntType) {
        assert(value > -Constants.maxArgSize)
        assert(value >= IntType.zero) // -1 is encoded as 0
        self.value = UInt8(truncatingIfNeeded: value) // Positive representation
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) { }
}

@usableFromInline
struct PositiveIntOptimizer<IntType: FixedWidthInteger>: EncodingOptimizer {
    let value: IntType

    @inline(__always)
    @usableFromInline var type: MajorType { .uint }
    @inline(__always)
    @usableFromInline var argument: UInt8 { IntType.argumentValue }
    @inline(__always)
    @usableFromInline var contentSize: Int { IntType.byteCount }

    @usableFromInline
    init(value: IntType) {
        assert(value >= Constants.maxArgSize)
        assert(value >= IntType.zero)
        self.value = value
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        value.write(to: &data)
    }
}

@usableFromInline
struct NegativeIntOptimizer<IntType: FixedWidthInteger>: EncodingOptimizer {
    let value: IntType

    @inline(__always)
    @usableFromInline var type: MajorType { .nint }
    @inline(__always)
    @usableFromInline var argument: UInt8 { IntType.argumentValue }
    @inline(__always)
    @usableFromInline var contentSize: Int { IntType.byteCount }

    @usableFromInline
    init(value: IntType) {
        assert(value >= -Constants.maxArgSize)
        assert(value >= IntType.zero) // -1 is encoded as 0
        self.value = value // Positive representation
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        value.write(to: &data)
    }
}
