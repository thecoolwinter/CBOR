//
//  CIDType.swift
//  CBOR
//
//  Created by Khan Winter on 10/14/25.
//

/// A type that represents a [CID](https://github.com/multiformats/cid). When encoded using ``CBOREncoder`` or
/// ``DAGCBOREncoder``, uses the tag `42`. This is the only allowed tagged data type when using ``DAGCBOREncoder``.
///
/// To use, conform your internal CID type to ``CIDType``. Do not conform standard types like `String` or `Data` to
/// ``CIDType``, or the encoder will attempt to encode all of those data as tagged items.
/// ```swift
/// struct CID: CIDType, Encodable {
///     let bytes: [UInt8]
///
///     func cidData() throws -> [UInt8] {
///         // Often you'll want to re-encode your CID from a human readable format to Base256.
///         return bytes
///     }
/// }
/// ```
/// Note that you **do not** need to prefix your data with the `NULL` character once encoded. This library will
/// handle that for you. It is invalid DAG-CBOR encoding to not include the prefixed byte.
public protocol CIDType: Encodable {
    associatedtype Bytes: Collection where Bytes.Element == UInt8
    func cidData() throws -> Bytes
}
