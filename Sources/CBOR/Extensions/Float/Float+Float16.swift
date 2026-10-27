//
//  Float+Float16.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

// Copied with modifications from: https://github.com/valpackett/SwiftCBOR

extension Float {
    // https://gist.github.com/martinkallman/5049614
    // Wayback machine required for the above link
    // rewritten to Swift + applied fixes from comments + added NaN/Inf checks
    @inlinable
    init?(halfPrecision x: UInt16) {
        switch x {
        case x where (x & 0x7fff) > 0x7c00:
            self = .nan
        case 0x7c00:
            self = .infinity
        case 0xfc00:
            self = -.infinity
        default:
            var t1 = UInt32(x & 0x7fff)        // Non-sign bits
            var t2 = UInt32(x & 0x8000)        // Sign bit
            let t3 = UInt32(x & 0x7c00)        // Exponent
            t1 <<= 13                          // Align mantissa on MSB
            t2 <<= 16                          // Shift sign bit into position
            t1 += 0x38000000                   // Adjust bias
            t1 = (t3 == 0 ? 0 : t1)            // Denormals-as-zero
            t1 |= t2                           // Re-insert sign bit
            self = Float(bitPattern: t1)
        }
    }
}
