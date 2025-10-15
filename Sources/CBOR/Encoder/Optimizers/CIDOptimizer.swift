//
//  CIDOptimizer.swift
//  CBOR
//
//  Created by Khan Winter on 10/14/25.
//

import Foundation

/// https://github.com/ipld/cid-cbor/
struct CIDOptimizer: EncodingOptimizer {
    var optimizer: EncodingOptimizer

    var type: MajorType { .tagged }
    var argument: UInt8 { 24 } // Small int for tag ID
    var headerSize: Int { 1 }
    var contentSize: Int { optimizer.size }

    init<T: CIDType>(_ cid: T) throws {
        optimizer = ByteStringOptimizer(value: [0] + (try cid.cidData()))
    }

    mutating func writeHeader(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        data[data.startIndex] = UInt8(CommonTags.cid.rawValue)
        data.removeFirst()
    }

    mutating func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        optimizer.write(to: &data)
    }
}
