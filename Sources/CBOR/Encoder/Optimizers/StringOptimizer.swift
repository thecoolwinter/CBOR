//
//  StringOptimizer.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

@inlinable
func StringOptimizer(value: String) -> EncodingOptimizer {
    let bytes = value.utf8
    if bytes.count < Constants.maxArgSize {
        return SmallStringOptimizer(value: bytes)
    } else {
        return LargeStringOptimizer(value: bytes)
    }
}

@usableFromInline
struct SmallStringOptimizer: EncodingOptimizer {
    let value: String.UTF8View

    @usableFromInline var type: MajorType { .string }
    @usableFromInline var argument: UInt8 { UInt8(truncatingIfNeeded: contentSize) }
    @usableFromInline var contentSize: Int { value.count }

    @usableFromInline
    init(value: String.UTF8View) {
        assert(value.count < Constants.maxArgSize)
        self.value = value
    }

    @usableFromInline
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        writeString(value, to: &data)
    }
}

@usableFromInline
struct LargeStringOptimizer: EncodingOptimizer {
    let value: String.UTF8View

    @usableFromInline var type: MajorType { .string }
    @usableFromInline var argument: UInt8 { countToArg(contentSize) }
    @usableFromInline var headerSize: Int { countToHeaderSize(contentSize) }
    @usableFromInline var contentSize: Int { value.count }

    @usableFromInline
    init(value: String.UTF8View) {
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
private func writeString(_ value: String.UTF8View, to data: inout Slice<UnsafeMutableRawBufferPointer>) {
    assert(data.count >= value.count)
    UnsafeMutableRawBufferPointer(rebasing: data).copyBytes(from: value)
    data.removeFirst(value.count)
}
