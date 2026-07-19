//
//  DataReader.swift
//  CBOR
//
//  Created by Khan Winter on 8/20/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A mutable struct used by the `CBORScanner` to iteratively scan a CBOR blob.
/// Since this isn't passed by reference, this represents the *entire* blob instead of a single value
/// like `DataRegion`.
///
/// This results in some duplicated code. I'd love to remove it but it works for now I suppose.
struct DataReader {
    private let data: Slice<UnsafeRawBufferPointer>
    private(set) var index = 0

    @inline(__always)
    @usableFromInline var count: Int {
        data.count - index
    }

    @inline(__always)
    @usableFromInline var isEmpty: Bool {
        data.count == index
    }

    init(data: Slice<UnsafeRawBufferPointer>) {
        self.data = data
    }

    @inline(__always)
    func canRead(_ numBytes: Int) -> Bool {
        count >= numBytes
    }

    @inline(__always)
    func canRead(_ numBytes: UInt) -> Bool {
        count >= numBytes
    }

    @discardableResult
    mutating func pop() -> UInt8 {
        assert(!isEmpty)
        defer { index += 1 }
        return _peek()
    }

    mutating func popArgument() -> UInt8 {
        pop() & 0b0001_1111
    }

    @discardableResult
    mutating func pop(_ num: Int) -> PlainDataRegion {
        assert(index + num <= data.count)
        defer { index += num }
        return PlainDataRegion(data: data[index..<(index + num)])
    }

    @inline(__always)
    func _peek() -> UInt8 {
        data[index]
    }

    @inline(__always)
    func peek() -> UInt8? {
        guard !isEmpty else { return nil }
        return _peek()
    }

    @inline(__always)
    func peekType() -> MajorType? {
        guard let raw = peek() else { return nil }
        return MajorType(rawValue: raw)
    }

    func peekArgument() -> UInt8? {
        guard let raw = peek() else { return nil }
        return raw & 0b0001_1111
    }

    @inline(__always)
    func peekNil() -> Bool {
        // This shouldn't modify the data stack. We just peek here.
        peekType() == .simple && peekArgument() == 22
    }

    /// Reads the next variable-sized integer off the data stack.
    @inlinable
    mutating func readNextInt<T: FixedWidthInteger>(as: T.Type) throws -> T {
        let arg = popArgument()
        let value = try data.readInt(as: T.self, argument: arg, from: data.startIndex + index)
        if let byteCount = arg.byteCount(), byteCount > 0 {
            pop(Int(byteCount))
        }
        return value
    }

    @inlinable
    func slice(_ range: Range<Int>) -> Slice<UnsafeRawBufferPointer> { data[range] }

    /// Compares complete encoded map keys using core deterministic order:
    /// encoded length first, then bytewise lexical order. A zero result means
    /// the key encodings are duplicates.
    func compareEncodedKeys(_ lhs: Range<Int>, _ rhs: Range<Int>) -> Int {
        if lhs.count != rhs.count {
            return lhs.count < rhs.count ? -1 : 1
        }

        for offset in 0..<lhs.count {
            let lhsByte = data[data.startIndex + lhs.lowerBound + offset]
            let rhsByte = data[data.startIndex + rhs.lowerBound + offset]
            if lhsByte != rhsByte {
                return lhsByte < rhsByte ? -1 : 1
            }
        }
        return 0
    }
}
