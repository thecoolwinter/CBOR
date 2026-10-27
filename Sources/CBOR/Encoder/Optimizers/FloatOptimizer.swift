//
//  FloatOptimizer.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

struct FloatOptimizer: EncodingOptimizer {
    let value: Float

    var type: MajorType { .simple }
    var argument: UInt8 { 26 }
    var contentSize: Int { 4 }

    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        assert(data.count >= 4)
        var bytes = value.bitPattern.bigEndian
        withUnsafeBytes(of: &bytes) { ptr in
            UnsafeMutableRawBufferPointer(rebasing: data).copyBytes(from: ptr)
        }
        data.removeFirst(4)
    }
}
