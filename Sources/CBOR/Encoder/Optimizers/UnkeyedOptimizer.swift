//
//  UnkeyedOptimizer.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

@inlinable
func UnkeyedOptimizer(value: [EncodingOptimizer]) -> EncodingOptimizer {
    if value.count < Constants.maxArgSize {
        return SmallUnkeyedOptimizer(value: value)
    } else {
        return LargeUnkeyedOptimizer(value: value)
    }
}

@usableFromInline
struct SmallUnkeyedOptimizer: EncodingOptimizer {
    fileprivate var value: [EncodingOptimizer]

    @usableFromInline var type: MajorType { .array }
    @usableFromInline var argument: UInt8 { UInt8(value.count) }
    @usableFromInline var contentSize: Int

    @usableFromInline
    init(value: [EncodingOptimizer]) {
        assert(value.count < Constants.maxArgSize)
        self.value = value
        var total = 0
        for v in value { total += v.size }
        self.contentSize = total
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        for optimizer in value {
            optimizer.write(to: &data)
        }
    }
}

@usableFromInline
struct LargeUnkeyedOptimizer: EncodingOptimizer {
    fileprivate var value: [EncodingOptimizer]

    @usableFromInline var type: MajorType { .array }
    @usableFromInline var argument: UInt8 { countToArg(value.count) }
    @usableFromInline var headerSize: Int { countToHeaderSize(value.count) }
    @usableFromInline var contentSize: Int

    @usableFromInline
    init(value: [EncodingOptimizer]) {
        assert(value.count >= Constants.maxArgSize)
        self.value = value
        var total = 0
        for v in value { total += v.size }
        self.contentSize = total
    }

    @usableFromInline
    func writeHeader(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        // Definite-length array count
        writeIntToHeader(value.count, data: &data)
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        for optimizer in value {
            optimizer.write(to: &data)
        }
    }
}
