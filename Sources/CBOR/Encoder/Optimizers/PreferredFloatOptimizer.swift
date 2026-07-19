//
//  PreferredFloatOptimizer.swift
//  CBOR
//
//  Core deterministic floating-point serialization.
//

/// Encodes a `Double` using the shortest IEEE 754 representation that preserves
/// its value exactly. NaN is normalized to the preferred half-precision value.
struct PreferredFloatOptimizer: EncodingOptimizer {
    enum Storage {
        case half(UInt16)
        case single(UInt32)
        case double(UInt64)
    }

    let storage: Storage

    var type: MajorType { .simple }

    var argument: UInt8 {
        switch storage {
        case .half: 25
        case .single: 26
        case .double: 27
        }
    }

    var contentSize: Int {
        switch storage {
        case .half: 2
        case .single: 4
        case .double: 8
        }
    }

    init(value: Double) {
        if value.isNaN {
            storage = .half(0x7e00)
            return
        }

        let single = Float(value)
        if Double(single) == value {
            if let half = single.exactHalfPrecisionBitPattern {
                storage = .half(half)
            } else {
                storage = .single(single.bitPattern)
            }
        } else {
            storage = .double(value.bitPattern)
        }
    }

    func writePayload(to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        switch storage {
        case var .half(bits):
            bits = bits.bigEndian
            write(bits, byteCount: 2, to: &data)
        case var .single(bits):
            bits = bits.bigEndian
            write(bits, byteCount: 4, to: &data)
        case var .double(bits):
            bits = bits.bigEndian
            write(bits, byteCount: 8, to: &data)
        }
    }

    private func write<T>(_ value: T, byteCount: Int, to data: inout Slice<UnsafeMutableRawBufferPointer>) {
        assert(data.count >= byteCount)
        var value = value
        withUnsafeBytes(of: &value) { ptr in
            UnsafeMutableRawBufferPointer(rebasing: data).copyBytes(from: ptr)
        }
        data.removeFirst(byteCount)
    }
}
