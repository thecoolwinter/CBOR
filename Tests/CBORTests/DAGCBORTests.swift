//
//  DAGCBORTests.swift
//  CBOR
//
//  Created by Khan Winter on 10/14/25.
//

import Foundation
import Testing
@testable import CBOR

// swiftlint:disable:next private_over_fileprivate
fileprivate struct CID: CIDType {
    let data: Data

    func cidData() throws -> Data {
        data
    }
}

@Suite
struct DAGCBORTests {
    @Test
    func `Custom CID Type Encoded Correctly`() throws {
        let cid = CID(data: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        let data = try DAGCBOREncoder().encode(cid)
        #expect(data.hexString() == "d82a4a00000102030405060708")
    }

    @Test
    func `Known valid base256 encoded ID`() throws {
        let cid = CID(data: "017112209fe4ccc6de16724f3a30c7e8f254f3c6471986acb1f8d8cf8e96ce2ad7dbe7fb".asHexData())
        let data = try DAGCBOREncoder().encode(cid)
        #expect(
            data.hexString() ==
            "d82a582500017112209FE4CCC6DE16724F3A30C7E8F254F3C6471986ACB1F8D8CF8E96CE2AD7DBE7FB".lowercased()
        )
    }
}
