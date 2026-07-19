//
//  UInt8+simpleLength.swift
//  CBOR
//
//  Created by Khan Winter on 9/1/25.
//

extension UInt8 {
    @inlinable
    func simpleLength() -> Int {
        switch self & 0b11111 {
        case 24:
            1 // One-byte simple value
        case 25:
            2 // Half-float
        case 26:
            4 // Float
        case 27:
            8 // Double
        default:
            0 // Just this byte.
        }
    }
}
