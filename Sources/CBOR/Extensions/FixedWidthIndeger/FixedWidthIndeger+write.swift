//
//  FixedWidthInteger+write.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

extension FixedWidthInteger {
    @inline(__always)
    @inlinable
    func write(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        assert(Self.byteCount <= data.count)
        withUnsafeBytes(of: self.bigEndian) { raw in
            UnsafeMutableRawBufferPointer(rebasing: data).copyMemory(from: raw)
            data.removeFirst(raw.count)
        }
    }

    @inline(__always)
    @usableFromInline static var argumentValue: UInt8 {
        switch byteCount {
        case 1: 24
        case 2: 25
        case 4: 26
        default: 27
        }
    }

    @inline(__always)
    @usableFromInline static var byteCount: Int {
        bitWidth / 8
    }
}
