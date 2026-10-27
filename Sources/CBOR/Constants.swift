//
//  Constants.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

@usableFromInline
enum Constants {
    // Values below this value can be encoded in the argument field.
    @inline(__always)
    @usableFromInline static let maxArgSize = 24

    @inline(__always)
    @usableFromInline static let breakCode: UInt8 = 0xFF

    @inline(__always)
    @usableFromInline static let indeterminateArg: UInt8 = 0b0001_1111
}
