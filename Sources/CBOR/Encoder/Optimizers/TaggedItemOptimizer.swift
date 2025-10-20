//
//  TaggedItemOptimizer.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct TaggedItemOptimizer: EncodingOptimizer {
    var sizeOptimizer: EncodingOptimizer
    var optimizer: EncodingOptimizer

    var type: MajorType { .tagged }
    var argument: UInt8 { sizeOptimizer.argument }
    var headerSize: Int { sizeOptimizer.contentSize }
    var contentSize: Int { optimizer.size }

    init(value: TaggedCBORItem, context: EncodingContext) throws {
        let storage = TopLevelTemporaryEncodingStorage()
        var container = SingleValueCBOREncodingContainer(parent: storage, context: context)
        try value.encodeTaggedData(using: &container)
        sizeOptimizer = IntOptimizer(value: Swift.type(of: value).tag)
        optimizer = storage.value
    }

    func writeHeader(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        sizeOptimizer.writePayload(to: &data)
    }

    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        optimizer.write(to: &data)
    }
}
