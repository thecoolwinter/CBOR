//
//  NilOptimizer.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

struct NilOptimizer: EncodingOptimizer {
    var type: MajorType { .simple }
    var argument: UInt8 { 22 }
    var contentSize: Int { 0 }

    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) { }
}
