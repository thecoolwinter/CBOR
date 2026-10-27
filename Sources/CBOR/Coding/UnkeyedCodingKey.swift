//
//  UnkeyedCodingKey.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

public struct UnkeyedCodingKey: CodingKey {
    var index: Int

    public var intValue: Int? { return index }
    public var stringValue: String { return String(index) }

    public init(intValue: Int) {
        index = intValue
    }
    public init?(stringValue: String) {
        guard let value = Int(stringValue) else {
            return nil
        }
        index = value
    }
}
