//
//  DecodableTests.swift
//  CBOR
//
//  Created by Khan Winter on 8/20/25.
//

import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@testable import CBOR

@Suite
struct DecodableTests {
    @Test
    func uint8() throws {
        var value: UInt8 = try CBORDecoder().decode(UInt8.self, from: [0])
        #expect(value == 0)
        value = try CBORDecoder().decode(UInt8.self, from: [1])
        #expect(value == 1)
        // Just below max arg size
        value = try CBORDecoder().decode(UInt8.self, from: [23])
        #expect(value == 23)
        // Just above max arg size
//        value = try CBORDecoder().decode(UInt8.self, from: [24, 24])
//        #expect(value == 24)
        // Max Int
        value = try CBORDecoder().decode(UInt8.self, from: [24, UInt8.max])
        #expect(value == UInt8.max)

        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt8.self, from: [128]) }
    }

    @Test
    func int8() throws {
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(Int8.self, from: [24, 255]) }
    }

    @Test
    func uint16() throws {
        var value = try CBORDecoder().decode(UInt16.self, from: [0])
        #expect(value == 0)
        value = try CBORDecoder().decode(UInt16.self, from: [1])
        #expect(value == 1)
        // Just below max arg size
        value = try CBORDecoder().decode(UInt16.self, from: [23])
        #expect(value == 23)
        // Just above max arg size
        value = try CBORDecoder().decode(UInt16.self, from: [24, 24])
        #expect(value == 24)

        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt16.self, from: [128]) }

        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt16.self, from: [25, 0, 1]) }

        value = try CBORDecoder().decode(UInt16.self, from: [25, 1, 1])
        #expect(value == 257)
        value = try CBORDecoder().decode(UInt16.self, from: [25, UInt8.max, UInt8.max])
        #expect(value == UInt16.max)
        // Missing bytes from end
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt16.self, from: [25]) }
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt16.self, from: [25, 0]) }
    }

    @Test
    func uint32() throws {
        var value: UInt32 = try CBORDecoder().decode(UInt32.self, from: [0])
        #expect(value == 0)
        value = try CBORDecoder().decode(UInt32.self, from: [1])
        #expect(value == 1)
        // Just below max arg size
        value = try CBORDecoder().decode(UInt32.self, from: [23])
        #expect(value == 23)

        value = try CBORDecoder().decode(UInt32.self, from: [25, 1, 1])
        #expect(value == 257)
        value = try CBORDecoder().decode(UInt32.self, from: [25, UInt8.max, UInt8.max])
        #expect(value == UInt16.max)
        // Missing bytes from end
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt32.self, from: [25]) }
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt32.self, from: [25, 0]) }

        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt32.self, from: [26, 0, 0, 0, 0]) }
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt32.self, from: [26, 0, 0, 0, 1]) }
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt32.self, from: [26, 0, 0, 1, 1]) }

        value = try CBORDecoder().decode(UInt32.self, from: [26, 0, 1, 1, 1])
        #expect(value == 65793)

        value = try CBORDecoder().decode(UInt32.self, from: [26, UInt8.max, UInt8.max, UInt8.max, UInt8.max])
        #expect(value == UInt32.max)
        // Missing bytes from end
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt32.self, from: [26]) }
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt32.self, from: [26, 0, 0, 0]) }
    }

    @Test
    func uint64() throws {
        var value: UInt64 = try CBORDecoder().decode(UInt64.self, from: [0])
        #expect(value == 0)
        value = try CBORDecoder().decode(UInt64.self, from: [1])
        #expect(value == 1)
        // Just below max arg size
        value = try CBORDecoder().decode(UInt64.self, from: [23])
        #expect(value == 23)

        value = try CBORDecoder().decode(UInt64.self, from: [25, 1, 1])
        #expect(value == 257)
        value = try CBORDecoder().decode(UInt64.self, from: [25, UInt8.max, UInt8.max])
        #expect(value == UInt16.max)
        // Missing bytes from end
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt64.self, from: [25]) }
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt64.self, from: [25, 0]) }

        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt64.self, from: [26, 0, 0, 0, 0]) }
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt64.self, from: [26, 0, 0, 0, 1]) }
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt64.self, from: [26, 0, 0, 1, 1]) }

        value = try CBORDecoder().decode(UInt64.self, from: [26, 0, 1, 1, 1])
        #expect(value == 65793)
        value = try CBORDecoder().decode(UInt64.self, from: [26, UInt8.max, UInt8.max, UInt8.max, UInt8.max])
        #expect(value == UInt32.max)
        // Missing bytes from end
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt64.self, from: [26]) }
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt64.self, from: [26, 0, 0, 0]) }

        #expect(throws: DecodingError.self) {
            try CBORDecoder().decode(UInt64.self, from: [27, 0, 0, 0, 0, 0, 0, 0, 0])
        }
        #expect(throws: DecodingError.self) {
            try CBORDecoder().decode(UInt64.self, from: [27, 0, 0, 0, 0, 0, 0, 0, 1])
        }
        #expect(throws: DecodingError.self) {
            try CBORDecoder().decode(UInt64.self, from: [27, 0, 0, 0, 0, 0, 0, 1, 1])
        }

        // Missing bytes from end
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(UInt64.self, from: [27]) }
        #expect(throws: DecodingError.self) {
            try CBORDecoder().decode(UInt64.self, from: [27, 0, 0, 0, 0, 0, 0, 0])
        }
    }

    @available(macOS 15.0, *)
    @Test
    func minInt() throws {
        let data = "3bffffffffffffffff".asHexData()
        let decoded = try CBORDecoder().decode(Int128.self, from: data)
        #expect(decoded == -18446744073709551616)
    }

    @Test
    func float() throws {
        let expected: Float = 100000.0
        let data = "fa47c35000".asHexData()
        let decoded = try CBORDecoder().decode(Float.self, from: data)
        #expect(decoded == expected)
    }

    @Test
    func double() throws {
        let expected: Double = 0.10035
        let data = "FB3FB9B089A0275254".asHexData()
        let decoded = try CBORDecoder().decode(Double.self, from: data)
        #expect(decoded == expected)
    }

    @Test(arguments: [
        ("6b68656c6c6f20776f726c64", "hello world"),
        ("60", ""),
        ("66e29da4efb88f", "❤️"),
        // swiftlint:disable:next line_length
        ("782F68656C6C6F20776F726C642068656C6C6F20776F726C642068656C6C6F20776F726C642068656C6C6F20776F726C64", "hello world hello world hello world hello world")
    ])
    func string(data: String, expected: String) throws {
        let data = data.asHexData()
        let string = try CBORDecoder().decode(String.self, from: data)
        #expect(string == expected)
    }

    @Test(arguments: [
        ("7FFF", ""),
        ("7F61416142FF", "AB")
    ])
    func indeterminateString(data: String, expected: String) throws {
        let data = data.asHexData()
        let string = try CBORDecoder(rejectIndeterminateLengths: false)
            .decode(String.self, from: data)
        #expect(string == expected)
    }

    @Test
    func emptyMap() throws {
        let data = "A0".asHexData()
        let dictionary = try CBORDecoder().decode([String: Int].self, from: data)
        #expect(dictionary.isEmpty)
    }

    @Test
    func simpleMap() throws {
        let data = "A262414201614102".asHexData()
        let dictionary = try CBORDecoder().decode([String: Int].self, from: data)
        #expect(dictionary == ["AB": 1, "A": 2])
    }

    @Test
    func unkeyedContainerHasCountForIndeterminate() throws {
        let data = "9F0203FF".asHexData()
        try data.withUnsafeBytes {
            let data = $0[...]
            let reader = DataReader(data: data)
            let options = DecodingOptions(rejectIndeterminateLengths: false)
            let scanner = CBORScanner(data: reader, options: options)
            let results = try scanner.scan()

            let context = DecodingContext(options: options, results: results)
            let container = SingleValueCBORDecodingContainer(
                context: context,
                data: results.load(at: 0)
            )

            var unkeyedContainer = try container.unkeyedContainer()
            #expect(unkeyedContainer.isAtEnd == false)
            #expect(unkeyedContainer.count == 2)
            #expect(unkeyedContainer.currentIndex == 0)

            let key1 = try unkeyedContainer.decode(Int.self)
            let key2 = try unkeyedContainer.decode(Int.self)
            #expect(key1 == 2)
            #expect(key2 == 3)

            #expect(unkeyedContainer.isAtEnd)
            #expect(unkeyedContainer.currentIndex == 2)
        }
    }

    @Test
    func array() throws {
        let twentyItems = "940101010101010101010101010101010101010101".asHexData()
        #expect(try CBORDecoder().decode([Int].self, from: twentyItems) == Array(repeating: 1, count: 20))
    }

    @Test
    func indeterminateArray() throws {
        let array = "9F0203FF".asHexData()
        #expect(try CBORDecoder(rejectIndeterminateLengths: false).decode([Int].self, from: array) == [2, 3])

        let twodArray = "9F9F0203FF9F0405FFFF".asHexData()
        let result = try CBORDecoder(rejectIndeterminateLengths: false).decode([[Int]].self, from: twodArray)
        #expect(result == [[2, 3], [4, 5]])
    }

    @Test
    func rejectsIndeterminateArrayWhenConfigured() throws {
        let array = "9FFF".asHexData()
        #expect(throws: DecodingError.self) {
            try CBORDecoder(rejectIndeterminateLengths: true).decode([Int].self, from: array)
        }

    }

    @Test
    func emptyData() throws {
        let data = Data()
        #expect(throws: DecodingError.self) { try CBORDecoder().decode(Data.self, from: data) }
    }

    @Test
    func date() throws {
        let data = "C11A5C295C00".asHexData()
        let expected = Date(timeIntervalSince1970: 1546214400.0)
        let value = try CBORDecoder().decode(Date.self, from: data)
        #expect(value == expected)
    }

    @Test(arguments: [
        ("F90000", 0),
        ("F93C00", 1.0),
        ("F9BE00", -1.5),
        ("F97C00", .infinity),
        ("F93E32", 1.548828125),
        ("F9F021", -8456)
    ])
    func float16(data: String, value: Float) throws {
        let data = data.asHexData()
        let decoded = try CBORDecoder().decode(Float.self, from: data)
        #expect(decoded == value)
    }

    @Test
    func recursionLimit() {
        #expect(throws: DecodingError.self) {
            // swiftlint:disable:next line_length
            let data = "a260818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818180652474797065726170702e62736b792e666565642e70736f74".asHexData()
            return try CBORDecoder().decode(AnyDecodable.self, from: data)
        }
    }
}
