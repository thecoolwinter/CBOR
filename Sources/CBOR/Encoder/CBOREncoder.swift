//
//  CBOREncoder.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Serializes ``Encodable`` objects using the CBOR serialization format.
///
/// To perform serialization, use the ``encode(_:)-6zhmp`` method to convert a Codable object to ``Data``. To
/// configure encoding behavior, either pass customization options in with
/// ``init(forceStringKeys:dateEncodingStrategy:)`` or modify ``options``.
public struct CBOREncoder {
    /// Options that determine the behavior of ``CBOREncoder``.
    public var options: EncodingOptions

    /// Create a new CBOR encoder.
    /// - Parameters:
    ///   - forceStringKeys: See ``EncodingOptions/forceStringKeys``.
    ///   - dateEncodingStrategy: See ``EncodingOptions/dateEncodingStrategy``.
    ///   - rejectTaggedItems: See ``EncodingOptions/rejectTaggedItems``.
    ///   - forceDoubleLengthEncoding: See ``EncodingOptions/forceDoubleLengthEncoding``.
    ///   - rejectInfAndNan: See ``EncodingOptions/rejectInfAndNan``.
    public init(
        forceStringKeys: Bool = false,
        dateEncodingStrategy: EncodingOptions.DateStrategy = .double,
        taggedItemsStrategy: EncodingOptions.TagStrategy = .accept,
        forceDoubleLengthEncoding: Bool = false,
        rejectInfAndNan: Bool = false
    ) {
        options = EncodingOptions(
            forceStringKeys: forceStringKeys,
            dateEncodingStrategy: dateEncodingStrategy,
            taggedItemsStrategy: taggedItemsStrategy,
            forceDoubleLengthEncoding: forceDoubleLengthEncoding,
            rejectInfAndNan: rejectInfAndNan
        )
    }

    /// Create a new CBOR encoder
    /// - Parameter options: The encoding options to use.
    public init(options: EncodingOptions) {
        self.options = options
    }

    /// Returns a CBOR-encoded representation of the value you supply.
    /// - Parameter value: The value to encode as CBOR data.
    /// - Returns: The encoded CBOR data.
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let tempStorage = TopLevelTemporaryEncodingStorage()

        let encodingContext = EncodingContext(options: options)
        let encoder = try SingleValueCBOREncodingContainer(parent: tempStorage, context: encodingContext)
        try encoder.encode(value)

        let dataSize = tempStorage.value.size
        var data = Data(count: dataSize)
        data.withUnsafeMutableBytes { ptr in
            var slice = ptr[...]
            tempStorage.value.write(to: &slice)
            assert(slice.isEmpty)
        }
        return data
    }
}
