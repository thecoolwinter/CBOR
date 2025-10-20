//
//  UnkeyedCBORDecodingContainer.swift
//  CBOR
//
//  Created by Khan Winter on 8/20/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct UnkeyedCBORDecodingContainer: DecodingContextContainer, UnkeyedDecodingContainer {
    let context: DecodingContext
    let data: DataRegion

    var hasConsumedEnd = false
    var count: Int?
    var isAtEnd: Bool { currentIndex == count }
    var currentIndex: Int = 0

    private var currentMapIndex: Int = 0

    init(context: DecodingContext, data: DataRegion) throws {
        self.context = context
        self.data = data

        try checkType(.array, forType: Array<Any>.self)
        guard let childCount = data.childCount else { fatalError("Array scanned but no child count recorded.") }
        self.count = childCount
        self.currentMapIndex = context.results.firstChildIndex(data.mapOffset)
    }

    /// Consumes one decoder off the scanned array.
    private mutating func consumeDecoder() throws -> SingleValueCBORDecodingContainer {
        defer {
            currentIndex += 1
            currentMapIndex = context.results.siblingIndex(currentMapIndex)
        }

        let region = context.results.load(at: currentMapIndex)
        return SingleValueCBORDecodingContainer(
            context: context.appending(UnkeyedCodingKey(intValue: currentIndex)),
            data: region
        )
    }

    mutating func decodeNil() throws -> Bool {
        context.results.load(at: currentMapIndex).isNil()
    }

    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try T(from: consumeDecoder())
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey> {
        try consumeDecoder().container(keyedBy: type)
    }

    mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
        try consumeDecoder().unkeyedContainer()
    }

    mutating func superDecoder() throws -> Decoder {
        try consumeDecoder()
    }
}
