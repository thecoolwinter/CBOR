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
/// struct CID: CIDType {
///     let data: Data
///
///     init(data: Data) {
///         self.data = data
///     }
///
///     init<Container: SingleValueDecodingContainer>(decodeTaggedDataUsing container: Container) throws {
///         var data = try container.decode(Data.self)
///         data.removeFirst()
///         self.data = data
///     }
///     
///     func encodeTaggedData<Container: SingleValueEncodingContainer>(using container: inout Container) throws {
///         try container.encode(Data([0x0]) + data)
///     }
/// }
/// ```
/// Note that you **need** to prefix your data with the `NULL` character once encoded. This library will
/// not handle that for you. It is invalid DAG-CBOR encoding to not include the prefixed byte.
public protocol CIDType: TaggedCBORItem {}

extension CIDType {
    /// The tag for all CID types is `42`.
    public static var tag: UInt { 42 }
}
