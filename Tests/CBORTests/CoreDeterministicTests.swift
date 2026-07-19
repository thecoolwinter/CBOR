//
//  CoreDeterministicTests.swift
//  CBOR
//

import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@testable import CBOR

@Suite
struct CoreDeterministicTests {
    private struct PartialValue: Decodable {
        let a: Int
    }

    private func strictDecoder() -> CBORDecoder {
        CBORDecoder(
            rejectIndeterminateLengths: true,
            rejectUnorderedMap: true,
            singleTopLevelItem: true,
            rejectNonCanonical: true
        )
    }

    @Test
    func ordersUnicodeKeysByEncodedBytes() throws {
        let encoded = try CBOREncoder().encode(["😀": 1, "aaa": 2])
        #expect(encoded == "a2636161610264f09f988001".asHexData())
    }

    @Test
    func usesShortestExactFloat() throws {
        let encoded = try CBOREncoder().encode(Double(1.5))
        #expect(encoded == "f93e00".asHexData())
        #expect(try CBORDecoder().decode(Double.self, from: encoded) == 1.5)

        let minimumHalfSubnormal = 1.0 / 16_777_216.0
        let subnormal = try CBOREncoder().encode(minimumHalfSubnormal)
        #expect(subnormal == "f90001".asHexData())
        #expect(try CBORDecoder().decode(Double.self, from: subnormal) == minimumHalfSubnormal)
    }

    @Test
    func rejectsNonMinimalUnknownValueOnlyInStrictMode() throws {
        let data = "a2616101617a1800".asHexData()
        #expect(try CBORDecoder().decode(PartialValue.self, from: data).a == 1)
        #expect(throws: DecodingError.self) {
            try strictDecoder().decode(PartialValue.self, from: data)
        }
    }

    @Test
    func rejectsUnorderedUnknownMapGlobally() {
        // { "a": 1, "z": { "b": 1, "a": 2 } }
        let data = "a2616101617aa2616201616102".asHexData()
        #expect(throws: DecodingError.self) {
            try strictDecoder().decode(PartialValue.self, from: data)
        }
    }

    @Test
    func rejectsNonPreferredFloatGlobally() {
        // The unknown value 1.5 is encoded as binary64 instead of binary16.
        let data = "a2616101617afb3ff8000000000000".asHexData()
        #expect(throws: DecodingError.self) {
            try strictDecoder().decode(PartialValue.self, from: data)
        }
    }
}
