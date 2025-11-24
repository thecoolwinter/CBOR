//
//  countTo+.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

@inline(__always)
func countToArg(_ count: Int) -> UInt8 {
    assert(count <= UInt64.max)
    return switch count {
    case 0...Int(UInt8.max): 24
    case 0...Int(UInt16.max): 25
    case 0...Int(UInt32.max): 26
    default: 27
    }
}

@inline(__always)
func countToHeaderSize(_ count: Int) -> Int {
    assert(count <= UInt64.max)
    return switch count {
    case 0...Int(UInt8.max): 1
    case 0...Int(UInt16.max): 2
    case 0...Int(UInt32.max): 4
    default: 8
    }
}

@inline(__always)
func writeIntToHeader<T: FixedWidthInteger>(_ int: T, data: inout Slice<UnsafeMutableRawBufferPointer>) {
    assert(int >= 0)
    assert(int <= UInt64.max)

    switch int {
    case 0...T(UInt8.max): UInt8(int).write(to: &data)
    case 0...T(UInt16.max): UInt16(int).write(to: &data)
    case 0...T(UInt32.max): UInt32(int).write(to: &data)
    default: UInt64(int).write(to: &data)
    }
}
