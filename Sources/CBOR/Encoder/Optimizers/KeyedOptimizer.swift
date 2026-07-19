//
//  KeyedOptimizer.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

@inlinable
func KeyedOptimizer(value: [String: EncodingOptimizer]) -> EncodingOptimizer {
    if value.count < Constants.maxArgSize {
        return SmallKeyedOptimizer(
            value: value,
            orderedUsing: { coreDeterministicStringKeyPrecedes($0.key, $1.key) },
            optimizer: { StringOptimizer(value: $0) }
        )
    } else {
        return LargeKeyedOptimizer(
            value: value,
            orderedUsing: { coreDeterministicStringKeyPrecedes($0.key, $1.key) },
            optimizer: { StringOptimizer(value: $0) }
        )
    }
}

@inlinable
func KeyedOptimizer(value: [Int: EncodingOptimizer]) -> EncodingOptimizer {
    if value.count < Constants.maxArgSize {
        return SmallKeyedOptimizer(
            value: value,
            orderedUsing: { coreDeterministicIntKeyPrecedes($0.key, $1.key) },
            optimizer: { IntOptimizer(value: $0) }
        )
    } else {
        return LargeKeyedOptimizer(
            value: value,
            orderedUsing: { coreDeterministicIntKeyPrecedes($0.key, $1.key) },
            optimizer: { IntOptimizer(value: $0) }
        )
    }
}

/// Core deterministic ordering compares the complete encoded keys by encoded
/// length and then lexicographically. For strings of equal UTF-8 length, the
/// CBOR headers are identical, so comparing the payload bytes is equivalent to
/// comparing the complete encodings.
@inlinable
func coreDeterministicStringKeyPrecedes(_ lhs: String, _ rhs: String) -> Bool {
    let lhsBytes = lhs.utf8
    let rhsBytes = rhs.utf8
    if lhsBytes.count != rhsBytes.count {
        return lhsBytes.count < rhsBytes.count
    }
    return lhsBytes.lexicographicallyPrecedes(rhsBytes)
}

/// Integer keys use their complete CBOR encoding for deterministic ordering.
/// Within a fixed encoded width and major type, the big-endian payload order is
/// the same as the order of the encoded non-negative argument.
@inlinable
func coreDeterministicIntKeyPrecedes(_ lhs: Int, _ rhs: Int) -> Bool {
    let lhsArgument = lhs < 0 ? UInt(-1 - lhs) : UInt(lhs)
    let rhsArgument = rhs < 0 ? UInt(-1 - rhs) : UInt(rhs)
    let lhsSize = coreDeterministicIntSize(lhsArgument)
    let rhsSize = coreDeterministicIntSize(rhsArgument)

    if lhsSize != rhsSize {
        return lhsSize < rhsSize
    }
    if (lhs < 0) != (rhs < 0) {
        return lhs >= 0
    }
    return lhsArgument < rhsArgument
}

@inlinable
func coreDeterministicIntSize(_ argument: UInt) -> Int {
    switch argument {
    case 0..<UInt(Constants.maxArgSize): 1
    case 0...UInt(UInt8.max): 2
    case 0...UInt(UInt16.max): 3
    case 0...UInt(UInt32.max): 5
    default: 9
    }
}

private struct KeyValue {
    var key: EncodingOptimizer
    var value: EncodingOptimizer

    @usableFromInline var size: Int {
        key.size + value.size
    }
}

@usableFromInline
struct SmallKeyedOptimizer<KeyType: Comparable & Hashable>: EncodingOptimizer {
    fileprivate var value: [KeyValue]

    @usableFromInline var type: MajorType { .map }
    @usableFromInline var argument: UInt8 { UInt8(value.count) }
    @usableFromInline var contentSize: Int

    @usableFromInline
    init(
        value: [KeyType: EncodingOptimizer],
        orderedUsing: ((key: KeyType, value: EncodingOptimizer), (key: KeyType, value: EncodingOptimizer)) -> Bool,
        optimizer: (KeyType) -> EncodingOptimizer
    ) {
        var size = 0
        var array: [KeyValue] = []
        array.reserveCapacity(value.count)

        self.value = value.sorted(by: orderedUsing).reduce(into: array, { array, keyValue in
            let optimized = KeyValue(key: optimizer(keyValue.key), value: keyValue.value)
            size += optimized.size
            array.append(optimized)
        })

        self.contentSize = size
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        for keyValue in value {
            keyValue.key.write(to: &data)
            keyValue.value.write(to: &data)
        }
    }
}

@usableFromInline
struct LargeKeyedOptimizer<KeyType: Comparable & Hashable>: EncodingOptimizer {
    fileprivate var value: [KeyValue]

    @usableFromInline var type: MajorType { .map }
    @usableFromInline var argument: UInt8 { countToArg(value.count) }
    @usableFromInline var headerSize: Int { countToHeaderSize(value.count) }
    @usableFromInline var contentSize: Int

    @usableFromInline
    init(
        value: [KeyType: EncodingOptimizer],
        orderedUsing: ((key: KeyType, value: EncodingOptimizer), (key: KeyType, value: EncodingOptimizer)) -> Bool,
        optimizer: (KeyType) -> EncodingOptimizer
    ) {
        var size = 0
        var array: [KeyValue] = []
        array.reserveCapacity(value.count)

        self.value = value.sorted(by: orderedUsing).reduce(into: array, { array, keyValue in
            let optimized = KeyValue(key: optimizer(keyValue.key), value: keyValue.value)
            size += optimized.size
            array.append(optimized)
        })

        self.contentSize = size
    }

    @usableFromInline
    func writeHeader(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        writeIntToHeader(value.count, data: &data)
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        for keyValue in value {
            keyValue.key.write(to: &data)
            keyValue.value.write(to: &data)
        }
    }
}
