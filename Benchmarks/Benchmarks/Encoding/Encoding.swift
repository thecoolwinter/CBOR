import Foundation
import Benchmark
//import SwiftCBOR
import CBOR

typealias EncoderObject = CBOREncoder

let benchmarks: @Sendable () -> Void = {
    struct Person: Codable {
        let name: String
        let age: Int
        let email: String
        let isActive: Bool
        let tags: [String]
    }

    struct Company: Codable {
        let name: String
        let founded: Int
        let employees: [Person]
        let metadata: [String: String]
    }

    // MARK: - Simple Object

    Benchmark("Simple Codable Object") { benchmark in
        let person = Person(
            name: "Alice",
            age: 30,
            email: "alice@example.com",
            isActive: true,
            tags: ["swift", "cbor", "benchmark"]
        )

        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(person)
        blackHole(data)
    }

    // MARK: - Complex Object

    Benchmark("Complex Codable Object") { benchmark in
        let person = Person(
            name: "Alice",
            age: 30,
            email: "alice@example.com",
            isActive: true,
            tags: ["swift", "cbor", "benchmark"]
        )

        let company = Company(
            name: "Acme Corp",
            founded: 1999,
            employees: Array(repeating: person, count: 10),
            metadata: ["industry": "tech", "location": "remote"]
        )

        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(company)
        blackHole(data)
    }

    // MARK: - String

    Benchmark("String") { benchmark in
        let string = String(repeating: "a", count: 1000)
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(string)
        blackHole(data)
    }

    // MARK: - String Small

    Benchmark("String Small") { benchmark in
        let stringSmall = "abc"
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(stringSmall)
        blackHole(data)
    }

    // MARK: - Data

    Benchmark("Data") { benchmark in
        let dataVal = Data(repeating: 0x42, count: 1024)
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(dataVal)
        blackHole(data)
    }

    // MARK: - Data Small

    Benchmark("Data Small") { benchmark in
        let dataSmall = Data([0x01, 0x02, 0x03])
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(dataSmall)
        blackHole(data)
    }

    // MARK: - Dictionary

    Benchmark("Dictionary") { benchmark in
        let dict = ["key": "value", "foo": "bar", "baz": "qux"]
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(dict)
        blackHole(data)
    }

    // MARK: - Dictionary Small

    Benchmark("Dictionary Small") { benchmark in
        let dictSmall = ["a": "b"]
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(dictSmall)
        blackHole(data)
    }

    // MARK: - Array

    Benchmark("Array") { benchmark in
        let array = Array(0..<1000)
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(array)
        blackHole(data)
    }

    // MARK: - Array Small

    Benchmark("Array Small") { benchmark in
        let arraySmall = [1, 2, 3]
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(arraySmall)
        blackHole(data)
    }

    // MARK: - Int

    Benchmark("Int") { benchmark in
        let intVal = 1234567891011
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(intVal)
        blackHole(data)
    }

    // MARK: - Int Small

    Benchmark("Int Small") { benchmark in
        let intValSmall = 42
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(intValSmall)
        blackHole(data)
    }

    // MARK: - Bool

    Benchmark("Bool") { benchmark in
        let boolVal = true
        let encoder = EncoderObject()
        benchmark.startMeasurement()
        let data = try encoder.encode(boolVal)
        blackHole(data)
    }
}
