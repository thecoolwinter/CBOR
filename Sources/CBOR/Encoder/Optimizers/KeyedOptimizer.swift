//
//  KeyedOptimizer.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

@inlinable
func KeyedOptimizer(value: [String: EncodingOptimizer]) -> EncodingOptimizer {
    if value.count < Constants.maxArgSize {
        return SmallKeyedOptimizer(value: value, optimizer: { StringOptimizer(value: $0) })
    } else {
        return LargeKeyedOptimizer(value: value, optimizer: { StringOptimizer(value: $0) })
    }
}

@inlinable
func KeyedOptimizer(value: [Int: EncodingOptimizer]) -> EncodingOptimizer {
    if value.count < Constants.maxArgSize {
        return SmallKeyedOptimizer(value: value, optimizer: { IntOptimizer(value: $0) })
    } else {
        return LargeKeyedOptimizer(value: value, optimizer: { IntOptimizer(value: $0) })
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
    init(value: [KeyType: EncodingOptimizer], optimizer: (KeyType) -> EncodingOptimizer) {
        var size = 0
        var array: [KeyValue] = []
        array.reserveCapacity(value.count)

        self.value = value.sorted(by: { $0.key < $1.key }).reduce(into: array, { array, keyValue in
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
    init(value: [KeyType: EncodingOptimizer], optimizer: (KeyType) -> EncodingOptimizer) {
        var size = 0
        var array: [KeyValue] = []
        array.reserveCapacity(value.count)

        self.value = value.sorted(by: { $0.key < $1.key }).reduce(into: array, { array, keyValue in
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
