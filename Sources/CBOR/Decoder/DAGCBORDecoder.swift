//
//  DAGCBORDecoder.swift
//  CBOR
//
//  Created by Khan Winter on 10/20/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Decodes ``Decodable`` objects from DAG-CBOR data.
///
/// This is really just a wrapper for ``CBORDecoder``, which constant configuration flags that ensure valid DAG-CBOR
/// data is decoded.
///
/// If this decoder is too strict, I'd suggest using ``CBORDecoder``, which will be much more flexible around decoding
/// than this type. You can also loosen specific flags using the options member of that struct. For instance, this
/// type will reject all unordered maps. If you find yourself needing to receive badly-defined DAG-CBOR, just
/// use ``CBORDecoder``.
public struct DAGCBORDecoder {
    /// The options that determine decoding behavior.
    let options: DecodingOptions

    /// Create a new DAG-CBOR decoder.
    public init() {
        self.options = DecodingOptions(
            rejectIndeterminateLengths: true,
            rejectIntKeys: true,
            rejectUnorderedMap: true,
            rejectUndefined: true,
            rejectNaN: true,
            rejectInf: true,
            singleTopLevelItem: true
        )
    }

    /// Decodes the given type from DAG-CBOR binary data.
    /// - Parameters:
    ///   - type: The decodable type to deserialize.
    ///   - data: The DAG-CBOR data to decode from.
    /// - Returns: An instance of the decoded type.
    /// - Throws: A ``DecodingError`` with context and a debug description for a failed deserialization operation.
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try CBORDecoder(options: options).decode(T.self, from: data)
    }
}
