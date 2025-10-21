//
//  RoundTripTests.swift
//  CBOR
//
//  Created by Khan Winter on 8/28/25.
//

import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@testable import CBOR

@Suite
struct RoundTripTests {
    @Test
    func int() throws {
        for _ in 0..<10 {
            let value = Int.random(in: 0..<Int.max)
            let data = try CBOREncoder().encode(value)
            let result = try CBORDecoder().decode(Int.self, from: data)
            #expect(value == result)
        }
    }

    @Test
    func bool() throws {
        var value = true
        var data = try CBOREncoder().encode(value)
        var result = try CBORDecoder().decode(Bool.self, from: data)
        #expect(value == result)

        value = false
        data = try CBOREncoder().encode(value)
        result = try CBORDecoder().decode(Bool.self, from: data)
        #expect(value == result)
    }

    @Test
    func float() throws {
        for _ in 0..<10 {
            let value = Float.random(in: -1000..<1000)
            let data = try CBOREncoder().encode(value)
            let result = try CBORDecoder().decode(Float.self, from: data)
            #expect(value == result)
        }
    }

    @Test
    func double() throws {
        for _ in 0..<10 {
            let value = Double.random(in: -1000..<1000)
            let data = try CBOREncoder().encode(value)
            let result = try CBORDecoder().decode(Double.self, from: data)
            #expect(value == result)
        }
    }

    @Test
    func data() throws {
        let value = Data([0xde, 0xad, 0xbe, 0xef])
        let encoded = try CBOREncoder().encode(value)
        let decoded = try CBORDecoder().decode(Data.self, from: encoded)
        #expect(value == decoded)
    }

    @Test
    func emptyData() throws {
        let value = Data()
        let encoded = try CBOREncoder().encode(value)
        let decoded = try CBORDecoder().decode(Data.self, from: encoded)
        #expect(value == decoded)
    }

    @Test
    func string() throws {
        let value = "Hello, CBOR 👋"
        let encoded = try CBOREncoder().encode(value)
        let decoded = try CBORDecoder().decode(String.self, from: encoded)
        #expect(value == decoded)
    }

    @Test
    func emptyString() throws {
        let value = ""
        let encoded = try CBOREncoder().encode(value)
        let decoded = try CBORDecoder().decode(String.self, from: encoded)
        #expect(value == decoded)
    }

    @Test
    func person() throws {
        let value = Person.mock
        let encoded = try CBOREncoder().encode(value)
        let decoded = try CBORDecoder().decode(Person.self, from: encoded)
        #expect(value.name == decoded.name)
        #expect(value.age == decoded.age)
        #expect(value.email == decoded.email)
        #expect(value.isActive == decoded.isActive)
        #expect(value.tags == decoded.tags)
    }

    @Test
    func company() throws {
        let value = Company.mock
        let encoded = try CBOREncoder().encode(value)
        let decoded = try CBORDecoder().decode(Company.self, from: encoded)
        #expect(value.name == decoded.name)
        #expect(value.founded == decoded.founded)
        #expect(value.employees.count == decoded.employees.count)
        #expect(value.metadata == decoded.metadata)

        // sanity check one employee too
        if let first = decoded.employees.first {
            #expect(first.name == Person.mock.name)
        }
    }

    @Test
    func dateEpoch() throws {
        let value = Date()
        let encoded = try CBOREncoder().encode(value)
        let decoded = try CBORDecoder().decode(Date.self, from: encoded)
        #expect(decoded.timeIntervalSince1970.rounded(.down) == value.timeIntervalSince1970.rounded(.down))
    }

    @Test
    func dateString() throws {
        let value = Date()
        let encoded = try CBOREncoder(dateEncodingStrategy: .string).encode(value)
        let decoded = try CBORDecoder().decode(Date.self, from: encoded)
        #expect(decoded.timeIntervalSince1970.rounded(.down) == value.timeIntervalSince1970.rounded(.down))
    }

    @Test
    func uuid() throws {
        let value = UUID()
        let encoded = try CBOREncoder().encode(value)
        let decoded = try CBORDecoder().decode(UUID.self, from: encoded)
        #expect(decoded == value)
    }

    @Test
    func map() throws {
        let value = ["a": 0]
        let encoded = try CBOREncoder().encode(value)
        let decoded = try CBORDecoder().decode([String: Int].self, from: encoded)
        #expect(decoded == value)
    }
}
