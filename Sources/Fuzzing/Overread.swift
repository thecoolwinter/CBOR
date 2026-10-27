//
//  Overread.swift
//  CBOR
//
//  Created by Khan Winter on 10/27/26.
//

import Foundation

/// A type that reads more elements than an unkeyed container contains.
struct Overread: Decodable {
    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        for _ in 0..<3 { _ = try c.decode(Int.self) }
    }
}
