//
//  EncodableTests.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@testable import CBOR

@Suite("EncodableTests")
struct EncodableTests {
    @Test
    func encodeNull() throws {
        let encoded = try CBOREncoder().encode(String?(nil))
        #expect(encoded == Data([0xf6]))
    }

    @Test
    func encodeBools() throws {
        let falseVal = try CBOREncoder().encode(false)
        #expect(falseVal == Data([0xf4]))

        let trueVal = try CBOREncoder().encode(true)
        #expect(trueVal == Data([0xf5]))
    }

    @Test
    func encodeInts() throws {
        // Less than 24
        let zero = try CBOREncoder().encode(0)
        #expect(zero == Data([0x00]))

        let eight = try CBOREncoder().encode(8)
        #expect(eight == Data([0x08]))

        let ten = try CBOREncoder().encode(10)
        #expect(ten == Data([0x0a]))

        let twentyThree = try CBOREncoder().encode(23)
        #expect(twentyThree == Data([0x17]))

        // Just bigger than 23
        let twentyFour = try CBOREncoder().encode(24)
        #expect(twentyFour == Data([0x18, 0x18]))

        let twentyFive = try CBOREncoder().encode(25)
        #expect(twentyFive == Data([0x18, 0x19]))

        // Bigger
        let hundred = try CBOREncoder().encode(100)
        #expect(hundred == Data([0x18, 0x64]))

        let thousand = try CBOREncoder().encode(1_000)
        #expect(thousand == Data([0x19, 0x03, 0xe8]))

        let million = try CBOREncoder().encode(1_000_000)
        #expect(million == Data([0x1a, 0x00, 0x0f, 0x42, 0x40]))

        let trillion = try CBOREncoder().encode(1_000_000_000_000)
        #expect(trillion == Data([0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00]))
    }

    @Test
    func encodeNegativeInts() throws {
        // Less than 24
        let minusOne = try CBOREncoder().encode(-1)
        #expect(minusOne == Data([0x20]))

        let minusTen = try CBOREncoder().encode(-10)
        #expect(minusTen == Data([0x29]))

        // Bigger
        let minusHundred = try CBOREncoder().encode(-100)
        #expect(minusHundred == Data([0x38, 0x63]))

        let minusThousand = try CBOREncoder().encode(-1_000)
        #expect(minusThousand == Data([0x39, 0x03, 0xe7]))

        let minusMillion = try CBOREncoder().encode(-1_000_001)
        #expect(minusMillion == Data([0x3A, 0x00, 0x0F, 0x42, 0x40]))

        let minusTrillion = try CBOREncoder().encode(-1_000_000_001)
        #expect(minusTrillion == Data([0x3A, 0x3B, 0x9A, 0xCA, 0x00]))
    }

    @Test
    func encodeFloat() throws {
        let value: Float = 100000.0
        let data = "fa47c35000".asHexData()
        let result = try CBOREncoder().encode(value)
        #expect(data == result)
    }

    @Test
    func encodeDouble() throws {
        let value: Double = 0.10035
        let data = "FB3FB9B089A0275254".asHexData()
        let result = try CBOREncoder().encode(value)
        #expect(data == result)
    }

    @Test
    func encodeStrings() throws {
        let empty = try CBOREncoder().encode("")
        #expect(empty == Data([0x60]))

        let a = try CBOREncoder().encode("a")
        #expect(a == Data([0x61, 0x61]))

        let IETF = try CBOREncoder().encode("IETF")
        #expect(IETF == Data([0x64, 0x49, 0x45, 0x54, 0x46]))

        let quoteSlash = try CBOREncoder().encode("\"\\")
        #expect(quoteSlash == Data([0x62, 0x22, 0x5c]))

        let littleUWithDiaeresis = try CBOREncoder().encode("\u{00FC}")
        #expect(littleUWithDiaeresis == Data([0x62, 0xc3, 0xbc]))
    }

    @Test
    func encodeByteStrings() throws {
        let fourByteByteString = try CBOREncoder().encode(Data([0x01, 0x02, 0x03, 0x04]))
        #expect(fourByteByteString == Data([0x44, 0x01, 0x02, 0x03, 0x04]))
    }

    @Test
    func mixedByteArraysEncodeCorrectly() throws {
        // TODO: Make the container swap to mixed mode if necessary.

        /// See note in ``UnkeyeyedCBOREncodingContainer`` about mixed collections of ints
        struct Mixed: Encodable {
            func encode(to encoder: any Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(UInt8.zero)
                try container.encode(UInt8.max)
                try container.encode("Hello World")
                try container.encode(1000000)
            }
        }

        let data = try CBOREncoder().encode(Mixed())
        // swiftlint:disable:next line_length
        #expect(data == Data([0x84, 0x00, 0x18, 0xff, 0x6b, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x57, 0x6f, 0x72, 0x6c, 0x64, 0x1a, 0x00, 0x0f, 0x42, 0x40]))
    }

    @Test
    func encodeArrays() throws {
        let empty = try CBOREncoder().encode([String]())
        #expect(empty == Data([0x80]))

        let oneTwoThree = try CBOREncoder().encode([1, 2, 3])
        #expect(oneTwoThree == Data([0x83, 0x01, 0x02, 0x03]))

        // swiftlint:disable:next line_length
        let lotsOfInts = try CBOREncoder().encode([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])

        // swiftlint:disable:next line_length
        #expect(lotsOfInts == Data([0x98, 0x19, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x18, 0x18, 0x19]))

        let nestedSimple = try CBOREncoder().encode([[1], [2, 3], [4, 5]])
        #expect(nestedSimple == Data([0x83, 0x81, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]))
    }

    @Test
    func encodeMaps() throws {
        let empty = try CBOREncoder().encode([String: String]())
        #expect(empty == Data([0xa0]))

        let stringToString = try CBOREncoder().encode(["a": "A", "b": "B", "c": "C", "d": "D", "e": "E"])
        #expect(stringToString.first! == 0xa5)

        let dataMinusFirstByte = stringToString[1...]
            .map { $0 }
            .chunked(into: 4)
            .sorted(by: { $0.lexicographicallyPrecedes($1) })
        let dataForKeyValuePairs: [[UInt8]] = [
            [0x61, 0x61, 0x61, 0x41],
            [0x61, 0x62, 0x61, 0x42],
            [0x61, 0x63, 0x61, 0x43],
            [0x61, 0x64, 0x61, 0x44],
            [0x61, 0x65, 0x61, 0x45]
        ]
        #expect(dataMinusFirstByte == dataForKeyValuePairs)

        let oneTwoThreeFour = try CBOREncoder().encode([1: 2, 3: 4])
        #expect(
            oneTwoThreeFour == Data([0xa2, 0x01, 0x02, 0x03, 0x04]) ||
            oneTwoThreeFour == Data([0xa2, 0x03, 0x04, 0x01, 0x02])
        )

        let encoder = CBOREncoder(forceStringKeys: true)
        let encodedWithStringKeys = try encoder.encode([1: 2, 3: 4])
        #expect(
            encodedWithStringKeys == Data([0xa2, 0x61, 0x31, 0x02, 0x61, 0x33, 0x04])
        )
    }

    @Test
    func encodeSimpleStructs() throws {
        struct MyStruct: Codable {
            let age: Int
            let name: String
        }

        let encoded = try CBOREncoder().encode(MyStruct(age: 27, name: "Ham")).map { $0 }

        #expect(
            encoded == [0xa2, 0x63, 0x61, 0x67, 0x65, 0x18, 0x1b, 0x64, 0x6e, 0x61, 0x6d, 0x65, 0x63, 0x48, 0x61, 0x6d]
        )
    }

    @Test
    func encodeMoreComplexStructs() throws {
        let encoder = CBOREncoder()

        let data = try encoder.encode(Company.mock)
        // swiftlint:disable:next line_length
        #expect(data == "A469656D706C6F796565738AA563616765181E65656D61696C71616C696365406578616D706C652E636F6D686973416374697665F5646E616D6565416C6963656474616773836573776966746463626F726962656E63686D61726BA563616765181E65656D61696C71616C696365406578616D706C652E636F6D686973416374697665F5646E616D6565416C6963656474616773836573776966746463626F726962656E63686D61726BA563616765181E65656D61696C71616C696365406578616D706C652E636F6D686973416374697665F5646E616D6565416C6963656474616773836573776966746463626F726962656E63686D61726BA563616765181E65656D61696C71616C696365406578616D706C652E636F6D686973416374697665F5646E616D6565416C6963656474616773836573776966746463626F726962656E63686D61726BA563616765181E65656D61696C71616C696365406578616D706C652E636F6D686973416374697665F5646E616D6565416C6963656474616773836573776966746463626F726962656E63686D61726BA563616765181E65656D61696C71616C696365406578616D706C652E636F6D686973416374697665F5646E616D6565416C6963656474616773836573776966746463626F726962656E63686D61726BA563616765181E65656D61696C71616C696365406578616D706C652E636F6D686973416374697665F5646E616D6565416C6963656474616773836573776966746463626F726962656E63686D61726BA563616765181E65656D61696C71616C696365406578616D706C652E636F6D686973416374697665F5646E616D6565416C6963656474616773836573776966746463626F726962656E63686D61726BA563616765181E65656D61696C71616C696365406578616D706C652E636F6D686973416374697665F5646E616D6565416C6963656474616773836573776966746463626F726962656E63686D61726BA563616765181E65656D61696C71616C696365406578616D706C652E636F6D686973416374697665F5646E616D6565416C6963656474616773836573776966746463626F726962656E63686D61726B67666F756E6465641907CF686D65746164617461A268696E6475737472796474656368686C6F636174696F6E6672656D6F7465646E616D656941636D6520436F7270".asHexData())
    }

    @Test
    func uint16() throws {
        let encoder = CBOREncoder()
        let data = try encoder.encode(1999)
        #expect(data == "1907CF".asHexData())
    }

    @Test(
        .disabled("Disabled until we can figure out how to make Float16 compile on all platforms."),
        arguments: [
            ("F90000", 0),
            ("F93C00", 1.0),
            ("F9BE00", -1.5),
            ("F97C00", .infinity),
            ("F93E32", 1.548828125),
            ("F9F021", -8456)
        ]
    )
    func halfFloat(expected: String, value: Float16) throws {
        let expectedData = expected.asHexData()
        let encoder = CBOREncoder()
        let data = try encoder.encode(value)
        #expect(data == expectedData)
    }

    @Test
    func duplicateKeysAreDeduplicatedOnEncode() throws {
        let encoder = CBOREncoder()
        struct Mock: Encodable {
            enum CodingKeys: String, CodingKey {
                case one
            }

            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(true, forKey: .one)
                try container.encode(false, forKey: .one)
            }
        }

        let data = try encoder.encode(Mock()).hexString()
        #expect(data == "a1636f6e65f4")
    }

    @Test
    func uuid() throws {
        let uuid = UUID(uuidString: "A0BDA068-60AD-4111-B4C9-04746791028B")
        let data = try CBOREncoder().encode(uuid).hexString()
        let expected = "d82550a0bda06860ad4111b4c904746791028b"
        #expect(data == expected)
    }
}
