//
//  UUID+TaggedCBORItem.swift
//  CBOR
//
//  Created by Khan Winter on 10/15/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension UUID: TaggedCBORItem {
    public static var tag: UInt { CommonTags.uuid.rawValue }

    public init<Container: SingleValueDecodingContainer>(decodeTaggedDataUsing container: Container) throws {
        let data = try container.decode(Data.self)
        guard data.count == 16 else { // UUID size
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Data decoded for UUID tag is not 16 bytes long."
            )
        }
        self = data.withUnsafeBytes { ptr in ptr.load(as: UUID.self) }
    }

    public func encodeTaggedData<Container: SingleValueEncodingContainer>(using encoder: inout Container) throws {
        try withUnsafeBytes(of: self) { ptr in
            try encoder.encode(Data(ptr))
        }
    }
}
