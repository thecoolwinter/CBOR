//
//  BoolOptimizer.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

struct BoolOptimizer: EncodingOptimizer {
    let value: Bool

    var type: MajorType { .simple }
    var argument: UInt8 { value ? 21 : 20 }
    var contentSize: Int { 0 }

    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) { }
}
