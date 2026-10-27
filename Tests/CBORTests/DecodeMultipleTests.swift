//
//  DecodeMultipleTests.swift
//  CBOR
//
//  Created by Khan Winter on 9/10/25.
//

import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@testable import CBOR

@Suite
struct DecodeMultipleTests {
    @Test
    func decodeMultipleInts() throws {
        var value: [UInt8] = try CBORDecoder().decodeMultiple(UInt8.self, from: [0])
        #expect(value == [0])
        value = try CBORDecoder().decodeMultiple(UInt8.self, from: [1, 1])
        #expect(value == [1, 1])
        // Just below max arg size
        value = try CBORDecoder().decodeMultiple(UInt8.self, from: [23, 23])
        #expect(value == [23, 23])
        // Just above max arg size
        value = try CBORDecoder().decodeMultiple(UInt8.self, from: [24, 24, 24, 24])
        #expect(value == [24, 24])
        // Max Int
        value = try CBORDecoder().decodeMultiple(UInt8.self, from: [24, UInt8.max])
        #expect(value == [UInt8.max])

        #expect(throws: DecodingError.self) { try CBORDecoder().decodeMultiple(UInt8.self, from: [128, 128]) }
        #expect(throws: DecodingError.self) { try CBORDecoder().decodeMultiple(UInt8.self, from: [23, 128]) }
    }

    @Test
    func mutlipleMaps() throws {
        let data = "A262414201614102A262414201614102".asHexData()
        let dictionary = try CBORDecoder().decodeMultiple([String: Int].self, from: data)
        #expect(dictionary == [["AB": 1, "A": 2], ["AB": 1, "A": 2]])
    }
}
