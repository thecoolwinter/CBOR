//
//  FloatOptimizer.swift
//  CBOR
//
//  Created by Khan Winter on 9/01/25.
//

// Would love to enable this, also see SingleValueCBOREncodingContainer for the other half of this
// but I'm not entirely sure how to make it work in that container and still compile on every machine
// and platform this library supports...

// @available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
// struct Float16Optimizer: EncodingOptimizer {
//     let value: Float16
//
//     var type: MajorType { .simple }
//     var argument: UInt8 { 25 }
//     var contentSize: Int { 2 }
//
//     init(value: Float16) {
//         self.value = value
//     }
//
//     func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
//         assert(data.count >= 2)
//         var bytes = value.bitPattern.bigEndian
//         withUnsafeBytes(of: &bytes) { ptr in
//             UnsafeMutableRawBufferPointer(rebasing: data).copyBytes(from: ptr)
//         }
//         data.removeFirst(2)
//     }
// }
