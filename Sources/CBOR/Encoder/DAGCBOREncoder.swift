//
//  DAGCBOREncoder.swift
//  CBOR
//
//  Created by Khan Winter on 10/14/25.
//

import Foundation

/// Serializes ``Encodable`` objects using the DAG-CBOR serialization format.
///
/// To perform serialization, use the ``encode`` method to convert a Codable object to ``Data``. To
/// configure encoding behavior, either pass customization options in with
/// ``init(dateEncodingStrategy:)`` or modify ``dateEncodingStrategy``.
///
/// This type has no performance differences from ``CBOREncoder``. Instead, it automatically configures the private
/// encoding options flags to generate always-valid DAG-CBOR encoded data.
///
/// - Warning: DAG-CBOR requires that implementations ***do not*** use tags for values such as dates. Because of this,
///            depending on the ``DAGCBOREncoder/dateEncodingStrategy``, date values will
///            be encoded without tag information as a different type.
public struct DAGCBOREncoder {
    /// Options that determine the behavior of ``DAGCBOREncoder``.
    public var dateEncodingStrategy: EncodingOptions.DateStrategy

    /// Create a new CBOR encoder.
    /// - Parameter dateEncodingStrategy: See ``EncodingOptions/dateEncodingStrategy``.
    public init(dateEncodingStrategy: EncodingOptions.DateStrategy = .double) {
        self.dateEncodingStrategy = dateEncodingStrategy
    }

    /// Returns a DAG-CBOR-encoded representation of the value you supply.
    /// - Parameter value: The value to encode as CBOR data.
    /// - Returns: The encoded CBOR data.
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        // Required overrides for valid DAG-CBOR encoding
        let options = EncodingOptions.dag(dateEncodingStrategy: dateEncodingStrategy)

        let tempStorage = TopLevelTemporaryEncodingStorage()

        let encodingContext = EncodingContext(options: options)
        let encoder = SingleValueCBOREncodingContainer(parent: tempStorage, context: encodingContext)
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
