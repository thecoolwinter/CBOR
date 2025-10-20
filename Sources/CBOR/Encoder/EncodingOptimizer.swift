//
//  EncodingOptimizer.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

@usableFromInline
protocol EncodingOptimizer {
    var type: MajorType { get }
    var argument: UInt8 { get }
    var headerSize: Int { get }
    var contentSize: Int { get }

    func writeHeader(to data: inout Slice<UnsafeMutableRawBufferPointer>)
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>)
}

extension EncodingOptimizer {
    @inline(__always)
    @inlinable var headerSize: Int { 0 }

    var size: Int { 1 + headerSize + contentSize }

    func write(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        assert(data.count >= size)

        // Write the type & argument
        assert(argument & 0b11100000 == 0)
        assert(type.bits & 0b00011111 == 0)
        assert(!data.isEmpty)

        data[data.startIndex] = type.bits | argument
        data.removeFirst()

        writeHeader(to: &data)
        writePayload(to: &data)
    }

    @inline(__always)
    @inlinable
    func writeHeader(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        // No-op by default
    }
}

struct EmptyOptimizer: EncodingOptimizer {
    var type: MajorType { .uint }
    var argument: UInt8 { 0 }
    var contentSize: Int { 0 }

    func writeHeader(to data: inout Slice<UnsafeMutableRawBufferPointer>) { }
    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) { }
}
