//
//  DoubleOptimizer.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

struct DoubleOptimizer: EncodingOptimizer {
    let value: Double

    var type: MajorType { .simple }
    var argument: UInt8 { 27 }
    var contentSize: Int { 8 }

    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        assert(data.count >= 8)
        var bytes = value.bitPattern.bigEndian
        withUnsafeBytes(of: &bytes) { ptr in
            UnsafeMutableRawBufferPointer(rebasing: data).copyBytes(from: ptr)
        }
        data.removeFirst(8)
    }
}
