//
//  Profiling.swift
//  CBOR
//
//  Created by Khan Winter on 10/20/25.
//

import CBOR
import Foundation

struct Profiling {
    @_optimize(none)
    func blackhole(_ val: some Any) { }

    func time(_ cbor: () throws -> Void, _ json: () throws -> Void) throws {
        guard #available(macOS 15.0, *) else { fatalError() }
        func calculateStats(_ measurements: [Duration]) -> (average: Double, stddev: Double) {
            let values = measurements.map {
                Double($0.components.seconds) + (Double($0.components.attoseconds) / 1e15)
            }
            let avg = values.reduce(0, +) / Double(values.count)

            let variance = values.map { pow($0 - avg, 2) }.reduce(0, +) / Double(values.count)
            let stddev = sqrt(variance)

            return (avg, stddev)
        }

        let iterations = 10

        var cborTimes: [Duration] = []
        var jsonTimes: [Duration] = []

        for _ in 0..<iterations {
            let cborTime = try SuspendingClock().measure {
                try cbor()
            }
            cborTimes.append(cborTime)

            let jsonTime = try SuspendingClock().measure {
                try json()
            }
            jsonTimes.append(jsonTime)
        }

        let cborStats = calculateStats(cborTimes)
        let jsonStats = calculateStats(jsonTimes)

        let percentChange = 100.0 * ((cborStats.average - jsonStats.average) / jsonStats.average)

        print("CBOR: \(String(format: "%.3f", cborStats.average)) ± \(String(format: "%.3f", cborStats.stddev)) ms")
        print("JSON: \(String(format: "%.3f", jsonStats.average)) ± \(String(format: "%.3f", jsonStats.stddev)) ms")
        print("Difference: \(percentChange > 0 ? "+" : "")\(String(format: "%.2f", percentChange))%")
    }

    func complex() throws {
        try time {
            for _ in 0..<1000 {
                blackhole(try CBOREncoder().encode(Company.mock))
            }
        } _: {
            for _ in 0..<1000 {
                blackhole(try JSONEncoder().encode(Company.mock))
            }
        }

    }

    func dictionary() throws {
        let data: [String: Int] = (0..<1000).reduce(into: [String: Int](), { $0[String(describing: $1)] = $1 })

        try time {
            for _ in 0..<100 {
                blackhole(try CBOREncoder().encode(data))
            }
        } _: {
            for _ in 0..<100 {
                blackhole(try JSONEncoder().encode(data))
            }
        }

    }

    func int() throws {
        try time {
            for _ in 0..<1000 {
                blackhole(try CBOREncoder().encode(Int.random(in: Int.min..<Int.max)))
            }
        } _: {
            for _ in 0..<1000 {
                blackhole(try JSONEncoder().encode(Int.random(in: Int.min..<Int.max)))
            }
        }

    }

    func string() throws {
        try time {
            for _ in 0..<1000 {
                blackhole(try CBOREncoder().encode("ABCDEFGHIJKLMNOP"))
            }
        } _: {
            for _ in 0..<1000 {
                blackhole(try JSONEncoder().encode("ABCDEFGHIJKLMNOP"))
            }
        }

    }

    func data() throws {
        try time {
            for _ in 0..<1000 {
                blackhole(try CBOREncoder().encode(Data([0x01, 0x02, 0x03, 0x04])))
            }
        } _: {
            for _ in 0..<1000 {
                blackhole(try JSONEncoder().encode(Data([0x01, 0x02, 0x03, 0x04])))
            }
        }

    }
}
