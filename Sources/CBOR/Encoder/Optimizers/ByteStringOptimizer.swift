//
//  ByteStringOptimizer.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

@inlinable
func ByteStringOptimizer<T: Collection>(value: T) -> EncodingOptimizer where T.Element == UInt8 {
    if value.count < Constants.maxArgSize {
        return SmallByteStringOptimizer(value: value)
    } else {
        return LargeByteStringOptimizer(value: value)
    }
}

@usableFromInline
struct SmallByteStringOptimizer<T: Collection>: EncodingOptimizer where T.Element == UInt8 {
    let value: T

    @usableFromInline var type: MajorType { .bytes }
    @usableFromInline var argument: UInt8 { UInt8(truncatingIfNeeded: contentSize) }
    @usableFromInline var contentSize: Int { value.count }

    @usableFromInline
    init(value: T) {
        assert(value.count < Constants.maxArgSize)
        self.value = value
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        writeString(value, to: &data)
    }
}

@usableFromInline
struct LargeByteStringOptimizer<T: Collection>: EncodingOptimizer where T.Element == UInt8 {
    let value: T

    @usableFromInline var type: MajorType { .bytes }
    @usableFromInline var argument: UInt8 { countToArg(contentSize) }
    @usableFromInline var headerSize: Int { countToHeaderSize(contentSize) }
    @usableFromInline var contentSize: Int { value.count }

    @usableFromInline
    init(value: T) {
        assert(value.count >= Constants.maxArgSize)
        self.value = value
    }

    @usableFromInline
    func writeHeader(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        writeIntToHeader(contentSize, data: &data)
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        writeString(value, to: &data)
    }
}

@inline(__always)
private func writeString<T: Collection>(
    _ value: T,
    to data: inout Slice<UnsafeMutableRawBufferPointer>
) where T.Element == UInt8 {
    assert(data.count >= value.count)
    UnsafeMutableRawBufferPointer(rebasing: data).copyBytes(from: value)
    data.removeFirst(value.count)
}
