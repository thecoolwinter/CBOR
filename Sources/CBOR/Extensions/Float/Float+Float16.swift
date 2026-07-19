//
//  Float+Float16.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

// Copied with modifications from: https://github.com/valpackett/SwiftCBOR

extension Float {
    @inlinable
    init?(halfPrecision x: UInt16) {
        let sign = UInt32(x & 0x8000) << 16
        let exponent = UInt32((x >> 10) & 0x001f)
        let fraction = UInt32(x & 0x03ff)

        switch (exponent, fraction) {
        case (0, 0):
            self = Float(bitPattern: sign)
        case (0, _):
            var significand = fraction
            var unbiasedExponent = -14
            while significand & 0x0400 == 0 {
                significand <<= 1
                unbiasedExponent -= 1
            }
            significand &= 0x03ff
            let floatExponent = UInt32(unbiasedExponent + 127) << 23
            self = Float(bitPattern: sign | floatExponent | (significand << 13))
        case (0x1f, 0):
            self = Float(bitPattern: sign | 0x7f80_0000)
        case (0x1f, _):
            self = Float(bitPattern: sign | 0x7f80_0000 | (fraction << 13))
        default:
            let floatExponent = UInt32(Int(exponent) - 15 + 127) << 23
            self = Float(bitPattern: sign | floatExponent | (fraction << 13))
        }
    }

    /// Returns the half-precision bit pattern only when the conversion is exact.
    /// NaN is normalized to the preferred deterministic representation.
    var exactHalfPrecisionBitPattern: UInt16? {
        let bits = bitPattern
        let sign = UInt16((bits >> 16) & 0x8000)
        let exponent = Int((bits >> 23) & 0xff)
        let fraction = bits & 0x007f_ffff

        if exponent == 0xff {
            return fraction == 0 ? sign | 0x7c00 : 0x7e00
        }

        if exponent == 0 {
            return fraction == 0 ? sign : nil
        }

        let unbiasedExponent = exponent - 127
        guard unbiasedExponent >= -24, unbiasedExponent <= 15 else {
            return nil
        }

        if unbiasedExponent >= -14 {
            guard fraction & 0x1fff == 0 else { return nil }
            let halfExponent = UInt16(unbiasedExponent + 15) << 10
            return sign | halfExponent | UInt16(fraction >> 13)
        }

        let significand = UInt32(0x0080_0000) | fraction
        let shift = UInt32(-unbiasedExponent - 1)
        let discardedMask = (UInt32(1) << shift) - 1
        guard significand & discardedMask == 0 else { return nil }

        let halfFraction = significand >> shift
        guard halfFraction > 0, halfFraction < 0x0400 else { return nil }
        return sign | UInt16(halfFraction)
    }
}
