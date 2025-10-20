//
//  KeyedCBORDecodingContainer.swift
//  CBOR
//
//  Created by Khan Winter on 8/20/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct KeyedCBORDecodingContainer<Key: CodingKey>: DecodingContextContainer, KeyedDecodingContainerProtocol {
    enum AnyKey: Hashable {
        case int(Int)
        case string(String)

        init(_ key: Key) {
            if let int = key.intValue {
                self = .int(int)
            } else {
                self = .string(key.stringValue)
            }
        }

        var keyValue: Key? {
            switch self {
            case .int(let int):
                Key(intValue: int)
            case .string(let string):
                Key(stringValue: string)
            }
        }
    }

    let context: DecodingContext
    let data: DataRegion

    var decodedKeys: [AnyKey: DataRegion] = [:]
    var allKeys: [Key] = []

    init(context: DecodingContext, data: DataRegion) throws {
        self.context = context
        self.data = data

        var decodedKeys: [AnyKey: DataRegion] = [:]

        try checkType(.map, forType: Dictionary<String, Any>.self)
        guard let childCount = data.childCount else { fatalError("Map scanned but no child count recorded.") }
        decodedKeys.reserveCapacity(childCount / 2)

        var mapOffset = context.results.firstChildIndex(data.mapOffset)
        for _ in 0..<childCount / 2 {
            let key = context.results.load(at: mapOffset)
            let decodedKey: AnyKey
            switch key.type {
            case .uint, .nint:
                let intVal = try SingleValueCBORDecodingContainer(context: context, data: key).decode(Int.self)
                decodedKey = AnyKey.int(intVal)
            case .string:
                let stringVal = try SingleValueCBORDecodingContainer(context: context, data: key).decode(String.self)
                decodedKey = AnyKey.string(stringVal)
            default:
                throw DecodingError.typeMismatch(
                    String.self,
                    context.error("Invalid key type found in map. Found \(key.type), expected an integer or string.")
                )
            }
            mapOffset = context.results.siblingIndex(mapOffset)

            let value = context.results.load(at: mapOffset)
            mapOffset = context.results.siblingIndex(mapOffset)

            decodedKeys[decodedKey] = value
        }

        self.decodedKeys = decodedKeys
        self.allKeys = Array(decodedKeys.keys.compactMap { $0.keyValue })
    }

    func contains(_ key: Key) -> Bool {
        decodedKeys[AnyKey(key)] != nil
    }

    func getRegion(forKey key: Key) throws -> DataRegion {
        guard let data = decodedKeys[AnyKey(key)] else {
            throw DecodingError.keyNotFound(key, context.error())
        }
        return data
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        try getRegion(forKey: key).isNil()
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let region = try getRegion(forKey: key)
        let container = SingleValueCBORDecodingContainer(context: context.appending(key), data: region)
        return try T.init(from: container)
    }

    func nestedContainer<NestedKey: CodingKey >(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> {
        let region = try getRegion(forKey: key)
        let container = try KeyedCBORDecodingContainer<NestedKey>(context: context.appending(key), data: region)
        return KeyedDecodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
        let region = try getRegion(forKey: key)
        return try UnkeyedCBORDecodingContainer(context: context.appending(key), data: region)
    }

    func superDecoder(forKey key: Key) throws -> any Decoder {
        fatalError()
    }

    func superDecoder() throws -> any Decoder {
        fatalError()
    }
}
