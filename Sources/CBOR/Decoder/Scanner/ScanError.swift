//
//  ScanError.swift
//  CBOR
//
//  Created by Khan Winter on 10/21/25.
//

@usableFromInline
enum ScanError: Error {
    case unexpectedEndOfData
    case invalidMajorType(byte: UInt8, offset: Int)
    case invalidSize(byte: UInt8, offset: Int)
    case expectedMajorType(offset: Int)
    case typeInIndeterminateString(type: MajorType, offset: Int)
    case rejectedIndeterminateLength(type: MajorType, offset: Int)
    case cannotRepresentInt(max: UInt, found: UInt, offset: Int)
    case recursionLimit
    case unreadDataAfterEnd
    case rejectedUndefined
    case unnecessaryInt
    case nonCanonicalMapKey(offset: Int, duplicate: Bool)
    case nonCanonicalSimple(offset: Int)

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func decodingError() -> DecodingError {
        switch self {
        case .unexpectedEndOfData:
            return DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Unexpected end of data.", underlyingError: self)
            )
        case let .invalidMajorType(byte, offset):
            return DecodingError.dataCorrupted(.init(
                codingPath: [],
                debugDescription: "Unexpected major type: \(String(byte, radix: 2)) at offset \(offset)",
                underlyingError: self
            ))
        case let .invalidSize(byte, offset):
            return DecodingError.dataCorrupted(.init(
                codingPath: [],
                debugDescription: "Unexpected size argument: \(String(byte, radix: 2)) at offset \(offset)",
                underlyingError: self
            ))
        case let .expectedMajorType(offset):
            return DecodingError.dataCorrupted(.init(
                codingPath: [],
                debugDescription: "Expected major type at offset \(offset)",
                underlyingError: self
            ))
        case let .typeInIndeterminateString(type, offset):
            return DecodingError.dataCorrupted(.init(
                codingPath: [],
                debugDescription: "Unexpected major type in indeterminate \(type) at offset \(offset)",
                underlyingError: self
            ))
        case let .rejectedIndeterminateLength(type, offset):
            return DecodingError.dataCorrupted(.init(
                codingPath: [],
                debugDescription: "Rejected indeterminate length type \(type) at offset \(offset)",
                underlyingError: self
            ))
        case let .cannotRepresentInt(max, found, offset):
            return DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Failed to decode integer with maximum \(max), "
                    + "found \(found) at \(offset)",
                    underlyingError: self
                )
            )
        case .recursionLimit:
            return DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Recursion depth limit exceeded (DecodingOptions.recursionDepth)",
                    underlyingError: self
                )
            )
        case .unreadDataAfterEnd:
            return DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Configured to reject CBOR data with trailing bytes (DecodingOptions."
                    + "singleTopLevelItem)",
                    underlyingError: self
                )
            )
        case .rejectedUndefined:
            return DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Configured to reject undefined values (DecodingOptions.rejectUndefined)",
                    underlyingError: self
                )
            )
        case .unnecessaryInt:
            return DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Found integer that was encoded in a larger data format than necessary",
                    underlyingError: self
                )
            )
        case let .nonCanonicalMapKey(offset, duplicate):
            let reason = duplicate ? "duplicate" : "out of core deterministic order"
            return DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Found map key that is \(reason) at offset \(offset)",
                    underlyingError: self
                )
            )
        case let .nonCanonicalSimple(offset):
            return DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Found non-canonical simple or floating-point value at offset \(offset)",
                    underlyingError: self
                )
            )
        }
    }
}
