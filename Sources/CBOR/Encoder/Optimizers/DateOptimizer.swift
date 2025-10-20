//
//  DateOptimizer.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct StringDateOptimizer: EncodingOptimizer {
    var optimizer: SmallStringOptimizer

    var type: MajorType { .tagged }
    var argument: UInt8 { 0 }
    var contentSize: Int { optimizer.size }

    init(value: Date) {
        #if canImport(FoundationEssentials)
        optimizer = SmallStringOptimizer(value: value.ISO8601Format().utf8)
        #else
        optimizer = SmallStringOptimizer(value: ISO8601DateFormatter().string(from: value).utf8)
        #endif
    }

    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        optimizer.write(to: &data)
    }
}

struct EpochDoubleDateOptimizer: EncodingOptimizer {
    var optimizer: DoubleOptimizer

    var type: MajorType { .tagged }
    var argument: UInt8 { 1 }
    var contentSize: Int { optimizer.size }

    init(value: Date) {
        optimizer = DoubleOptimizer(value: value.timeIntervalSince1970)
    }

    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        optimizer.write(to: &data)
    }
}

struct EpochFloatDateOptimizer: EncodingOptimizer {
    var optimizer: FloatOptimizer

    var type: MajorType { .tagged }
    var argument: UInt8 { 1 }
    var contentSize: Int { optimizer.size }

    init(value: Date) {
        optimizer = FloatOptimizer(value: Float(value.timeIntervalSince1970))
    }

    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        optimizer.write(to: &data)
    }
}
