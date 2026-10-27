//
//  OverreadTests.swift
//  CBOR
//
//  Created by Khan Winter on 10/27/26.
//

import Testing
@testable import CBOR

struct Overread: Decodable {
    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        for _ in 0..<3 { _ = try c.decode(Int.self) }
    }
}

@Suite
struct OverreadTests {
    @Test
    func `Throws error when attempting to read past the end of an unkeyed container`() throws {
        #expect(throws: DecodingError.self ) {
            try CBORDecoder().decode(Overread.self, from: [0x81, 0x01])
        }
    }
}
