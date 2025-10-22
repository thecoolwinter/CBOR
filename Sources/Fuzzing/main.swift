//
//  fuzz.swift
//  CBOR
//
//  Created by Khan Winter on 8/29/25.
//

import CBOR
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@_optimize(none)
func blackhole(_ val: some Any) { }

/// Fuzzing entry point
@_cdecl("LLVMFuzzerTestOneInput")
public func fuzz(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
    let bytes = UnsafeRawBufferPointer(start: start, count: count)
    let data = Data(bytes)

    // Try decoding against a bunch of standard types.
    // Each attempt is independent — errors are ignored, crashes are what fuzzing is for.
    func tryDecode<T: Decodable>(_ type: T.Type) {
        do {
            blackhole(try CBORDecoder(rejectIndeterminateLengths: false).decode(T.self, from: data))
            blackhole(try CBORDecoder(rejectIndeterminateLengths: true).decode(T.self, from: data))
            blackhole(try CBORDecoder(rejectIndeterminateLengths: false).decodeMultiple(T.self, from: data))
            blackhole(try CBORDecoder(rejectIndeterminateLengths: true).decodeMultiple(T.self, from: data))
        } catch {
            // ignore decode errors
        }
    }

    // Scalars
    tryDecode(Bool.self)
    tryDecode(Int.self)
    tryDecode(Int8.self)
    tryDecode(Int16.self)
    tryDecode(Int32.self)
    tryDecode(Int64.self)
    tryDecode(UInt.self)
    tryDecode(UInt8.self)
    tryDecode(UInt16.self)
    tryDecode(UInt32.self)
    tryDecode(UInt64.self)
    tryDecode(Float.self)
    tryDecode(Double.self)
    tryDecode(String.self)
    tryDecode(Data.self)

    // Optionals
    tryDecode(Optional<Int>.self)
    tryDecode(Optional<String>.self)
    tryDecode(Optional<Data>.self)

    // Collections
    tryDecode([Int].self)
    tryDecode([String].self)
    tryDecode([Data].self)
    tryDecode([String: Int].self)
    tryDecode([String: String].self)

    // Nested combinations
    tryDecode([[Int]].self)
    tryDecode([String: [String: Int]].self)

    // Any decodable
    tryDecode(AnyDecodable.self)

    // Encode
    do {
        try blackhole(CBOREncoder().encode(Data(bytes: start, count: count)))
        try blackhole(DAGCBOREncoder().encode(Data(bytes: start, count: count)))
    } catch {
        print("Failed to encode")
        return -1
    }

    return 0
}
