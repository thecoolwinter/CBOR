//
//  Person.swift
//  CBOR
//
//  Created by Khan Winter on 10/20/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct Person: Codable {
    let name: String
    let age: Int
    let email: String
    let isActive: Bool
    let tags: [String]

    static let mock = Person(
        name: "Alice",
        age: 30,
        email: "alice@example.com",
        isActive: true,
        tags: ["swift", "cbor", "benchmark"]
    )
}

struct Company: Codable {
    let name: String
    let founded: Int
    let employees: [Person]
    let metadata: [String: String]

    static let mock = Company(
        name: "Acme Corp",
        founded: 1999,
        employees: Array(repeating: Person.mock, count: 10),
        metadata: ["industry": "tech", "location": "remote"]
    )
}
