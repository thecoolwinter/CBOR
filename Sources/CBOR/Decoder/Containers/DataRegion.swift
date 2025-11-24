//
//  DataRegion.swift
//  CBOR
//
//  Created by Khan Winter on 8/24/25.
//

struct PlainDataRegion {
    private let data: Slice<UnsafeRawBufferPointer>

    init(data: Slice<UnsafeRawBufferPointer>) {
        self.data = data
    }

    var count: Int { data.count }
    var isEmpty: Bool { data.isEmpty }

    @inlinable
    subscript(index: Int) -> UInt8 {
        data[data.startIndex + index]
    }
}

struct DataRegion {
    let type: MajorType
    let argument: UInt8
    let childCount: Int?
    let mapOffset: Int
    // Does not include the type and argument byte
    private let data: Slice<UnsafeRawBufferPointer>

    var count: Int { data.count }
    var isEmpty: Bool { data.isEmpty }
    var globalIndex: Int { data.startIndex }

    init(type: MajorType, argument: UInt8, childCount: Int?, mapOffset: Int, data: Slice<UnsafeRawBufferPointer>) {
        self.type = type
        self.argument = argument
        self.childCount = childCount
        self.mapOffset = mapOffset
        self.data = data
    }

    @inlinable
    subscript(index: Int) -> UInt8 {
        data[data.startIndex + index]
    }

    subscript(range: Range<Int>) -> Slice<UnsafeRawBufferPointer> {
        data[(data.startIndex + range.lowerBound)..<(data.startIndex + range.upperBound)]
    }

    @inline(__always)
    func canRead(_ numBytes: Int) -> Bool {
        data.canRead(numBytes)
    }

    func _peek() -> UInt8 {
        data[data.startIndex]
    }

    func peek() -> UInt8? {
        guard !isEmpty else { return nil }
        return _peek()
    }

    func isNil() -> Bool {
        // This shouldn't modify the data stack. We just peek here.
        type == .simple && (argument == 22 || argument == 23)
    }

    /// Reads the next variable-sized integer off the data stack.
    @inlinable
    func readInt<T: FixedWidthInteger>(as: T.Type) throws -> T {
        try data.readInt(as: T.self, argument: argument)
    }

    @inlinable
    func read<F: FixedWidthInteger>(as: F.Type) throws -> F {
        try data.read(as: F.self)
    }
}

internal extension Slice<UnsafeRawBufferPointer> {
    @inline(__always)
    @inlinable
    func canRead(_ numBytes: Int) -> Bool {
        count >= numBytes
    }

    @inline(__always)
    @inlinable
    func canRead(_ numBytes: Int, from index: Index) -> Bool {
        index + numBytes <= endIndex
    }

    @inlinable
    func readInt<T: FixedWidthInteger>(as: T.Type, argument: UInt8) throws -> T {
        try readInt(as: T.self, argument: argument, from: startIndex)
    }

    @inline(__always)
    @usableFromInline
    func checkIntConversion<T: FixedWidthInteger, F: FixedWidthInteger>(_ type: T.Type, val: F) throws {
        guard val <= T.max else {
            throw ScanError.cannotRepresentInt(max: UInt(T.max), found: UInt(val), offset: startIndex)
        }
    }

    @inline(__always)
    @usableFromInline
    func checkIntSize<T: FixedWidthInteger, F: FixedWidthInteger>(_ value: T, previousSize: F) throws {
        guard value >= previousSize else {
            throw ScanError.unnecessaryInt
        }
    }

    @inlinable
    func readInt<T: FixedWidthInteger>(as: T.Type, argument: UInt8, from index: Index) throws -> T {
        let byteCount = argument
        switch byteCount {
        case let value where value < Constants.maxArgSize:
            let intVal = value
            try checkIntConversion(T.self, val: intVal)
            return T(intVal)
        case 24:
            let intVal = try read(as: UInt8.self, from: index)
            try checkIntConversion(T.self, val: intVal)
            try checkIntSize(intVal, previousSize: Constants.maxArgSize)
            return T(intVal)
        case 25:
            let intVal = try read(as: UInt16.self, from: index)
            try checkIntConversion(T.self, val: intVal)
            try checkIntSize(intVal, previousSize: UInt8.max)
            return T(intVal)
        case 26:
            let intVal = try read(as: UInt32.self, from: index)
            try checkIntConversion(T.self, val: intVal)
            try checkIntSize(intVal, previousSize: UInt16.max)
            return T(intVal)
        case 27:
            let intVal = try read(as: UInt64.self, from: index)
            try checkIntConversion(T.self, val: intVal)
            try checkIntSize(intVal, previousSize: UInt32.max)
            return T(intVal)
        default:
            throw ScanError.invalidSize(byte: byteCount, offset: startIndex)
        }
    }

    @inlinable
    func read<F: FixedWidthInteger>(as: F.Type) throws -> F {
        try read(as: F.self, from: startIndex)
    }

    @inlinable
    func read<F: FixedWidthInteger>(as: F.Type, from index: Index) throws -> F {
        guard canRead(F.byteCount, from: index) else {
            throw ScanError.unexpectedEndOfData
        }
        var val = F.zero
        for idx in 0..<(F.byteCount) {
            let shift = (F.byteCount - idx - 1) * 8
            val |= F(self[index + idx]) << shift
        }
        return F(val)
    }
}
