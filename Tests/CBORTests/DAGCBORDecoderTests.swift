//
//  DAGCBORDecoderTests.swift
//  CBOR
//
//  Created by Khan Winter on 10/21/25.
//

import Testing
@testable import CBOR

@Suite
struct DAGCBORDecoderTests {
    @Test
    func shortMap() throws {
        let data = "a1616100".asHexData()
        let decoded = try DAGCBORDecoder().decode([String: Int].self, from: data)
        #expect(decoded == ["a": 0])
    }

    @Test
    func rejectUnorderedMaps() throws {
        let data = "a361610162616103616202".asHexData()
        #expect(throws: DecodingError.self) {
            return try DAGCBORDecoder().decode([String: Int].self, from: data)
        }
    }

    @Test
    func rejectOtherUnorderedMaps() throws {
        let data = "a2616201616100".asHexData()
        #expect(throws: DecodingError.self) {
            return try DAGCBORDecoder().decode([String: Int].self, from: data)
        }
    }

    @Test
    func rejectConcatenatedItems() throws {
        var data = "0000".asHexData()
        #expect(throws: DecodingError.self) {
            return try DAGCBORDecoder().decode(Int.self, from: data)
        }

        data = "0000AA".asHexData()
        #expect(throws: DecodingError.self) {
            return try DAGCBORDecoder().decode(Int.self, from: data)
        }
    }
}
