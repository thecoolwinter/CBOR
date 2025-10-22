//
//  TaggedCBORItem.swift
//  CBOR
//
//  Created by Khan Winter on 10/15/25.
//

/// Protocol for tagged item encoding. Conform types to this to have them encoded in a tag container.
///
/// Types that conform to this protocol must be `Codable` but are required to implement the method and initializer
/// required by this protocol to ensure extra containers are not created between the tag container and the real data.
/// This library implements this for Foundations ``Foundation/UUID`` type, Dates are handled as a special case.
///
/// For an example conformance, see ``CIDType``.
public protocol TaggedCBORItem: Codable {
    static var tag: UInt { get }

    init<Container: SingleValueDecodingContainer>(decodeTaggedDataUsing container: Container) throws
    func encodeTaggedData<Container: SingleValueEncodingContainer>(using container: inout Container) throws
}

/// Helper for getting the static member from an instance of the protocol. Otherwise sometimes has a crash at runtime
/// when trying to do `T as! TaggedCBORItem.self` even if `T` is a `TaggedCBORItem`. Probably due to some fuckery in
/// Foundation's stuff with UUID in particular. This fixes that though.
extension TaggedCBORItem {
    var __staticTagLookup: UInt { Self.tag }
}
