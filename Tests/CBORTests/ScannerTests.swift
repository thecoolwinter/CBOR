//
//  ScannerTests.swift
//  CBOR
//
//  Created by Khan Winter on 8/24/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import Testing
@testable import CBOR

@Suite
struct ScannerTests {
    @Test(arguments: [(24, 1), (25, 2), (26, 4), (27, 8)])
    func int(argument: UInt8, byteCount: Int) throws {
        let payload = minimalPayload(byteCount: byteCount)
        let data = Data([argument] + payload)
        try data.withUnsafeBytes {
            let data = $0[...]

            let scanner = CBORScanner(data: DataReader(data: data))
            let results = try scanner.scan()
            let map = results.contents()
            #expect(map == [Int(MajorType.uint.bits | argument), 1, byteCount])

            #expect(results.load(at: 0).type == .uint)
            #expect(results.load(at: 0).argument == argument)
            #expect(results.load(at: 0).count == byteCount)
        }
    }

    @Test(arguments: [(24, 1), (25, 2), (26, 4), (27, 8)])
    func intInvalidSize(argument: UInt8, maxSize: Int) {
        for count in 0..<maxSize {
            let data = Array(repeating: UInt8.zero, count: count)
            Data([argument] + data).withUnsafeBytes {
                let data = $0[...]
                #expect(throws: ScanError.self) {
                    try CBORScanner(data: DataReader(data: data)).scan()
                }
            }
        }
    }

    @Test(arguments: [(24, 1), (25, 2), (26, 4), (27, 8)])
    func nint(argument: UInt8, byteCount: Int) throws {
        let payload = minimalPayload(byteCount: byteCount)
        let data = Data([MajorType.nint.bits | argument] + payload)
        try data.withUnsafeBytes {
            let data = $0[...]
            let scanner = CBORScanner(data: DataReader(data: data))
            let results = try scanner.scan()
            let map = results.contents()
            #expect(map == [Int(MajorType.nint.bits | argument), 1, byteCount])
        }
    }

    private func minimalPayload(byteCount: Int) -> [UInt8] {
        switch byteCount {
        case 1: [0x18]
        case 2: [0x01, 0x00]
        case 4: [0x00, 0x01, 0x00, 0x00]
        case 8: [0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
        default: preconditionFailure("Unsupported integer width")
        }
    }

    @Test(arguments: [(24, 1), (25, 2), (26, 4), (27, 8)])
    func nintInvalidSize(argument: UInt8, maxSize: Int) {
        for count in 0..<maxSize {
            let data = Data([MajorType.nint.bits | argument] + Array(repeating: UInt8.zero, count: count))
            data.withUnsafeBytes {
                let data = $0[...]
                #expect(throws: ScanError.self) {
                    try CBORScanner(data: DataReader(data: data)).scan()
                }
            }
        }
    }

    @Test(arguments: [
        ("BFFF", [MajorType.map.intValue, 0, 0, 0, 2]), // Empty, indeterminate map
        ( // Nested, empty, indeterminate map: { "": {} }
            "BF60BFFFFF",
            [MajorType.map.intValue, 2, 8, 0, 5, MajorType.string.intValue, 2, 0, MajorType.map.intValue, 0, 0, 2, 2]
        )
    ])
    func indeterminateMap(data: String, expectedMap: [Int]) throws {
        let data = data.asHexData()
        try data.withUnsafeBytes {
            let data = $0[...]
            let options = DecodingOptions(rejectIndeterminateLengths: false)
            let scanner = CBORScanner(data: DataReader(data: data), options: options)
            let results = try scanner.scan()
            let map = results.contents()
            #expect(map == expectedMap)
        }
    }

    @Test(arguments: [
        ("A0", [MajorType.map.intValue, 0, 0, 1, 0]), // Empty map
        ( // { "": 1, "": 2 }
            "A260016002",
            [
                MajorType.map.intValue, 4, 12, 1, 4,
                MajorType.string.intValue, 2, 0,
                (MajorType.uint.intValue | 1), 3, 0,
                MajorType.string.intValue, 4, 0,
                (MajorType.uint.intValue | 2), 5, 0]
        )
    ])
    func map(data: String, expectedMap: [Int]) throws {
        let data = data.asHexData()
        try data.withUnsafeBytes {
            let data = $0[...]
            let scanner = CBORScanner(data: DataReader(data: data))
            let results = try scanner.scan()
            let map = results.contents()
            #expect(map == expectedMap)
        }
    }

    @Test
    func indeterminateNestedArray() throws {
        let expectedMap = [128, 2, 22, 0, 10, 128, 2, 6, 1, 4, 2, 3, 0, 3, 4, 0, 128, 2, 6, 5, 4, 4, 7, 0, 5, 8, 0]
        let data = "9F9F0203FF9F0405FFFF".asHexData()
        try data.withUnsafeBytes {
            let data = $0[...]
            let options = DecodingOptions(rejectIndeterminateLengths: false)
            let scanner = CBORScanner(data: DataReader(data: data), options: options)
            let results = try scanner.scan()
            let map = results.contents()
            #expect(map == expectedMap)
        }
    }
}
