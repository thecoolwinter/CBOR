//
//  KeyedCBOREncodingContainer.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

struct KeyedCBOREncodingContainer<
    Key: CodingKey,
    ParentStorage: TemporaryEncodingStorage
>: KeyedEncodingContainerProtocol {
    private let storage: KeyBuffer
    private let context: EncodingContext

    var codingPath: [CodingKey] { context.codingPath }

    init(parent: ParentStorage, context: EncodingContext) {
        self.storage = KeyBuffer(parent: parent, context: context)
        self.context = context
    }

    func encoder(for key: CodingKey) throws -> SingleValueCBOREncodingContainer<KeyBuffer.Keyed> {
        return try .init(parent: storage.withKey(key), context: context.appending(key))
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        try encoder(for: key).encode(value)
    }

    mutating func encodeNil(forKey key: Key) throws {
        storage.withKey(key).register(NilOptimizer())
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        KeyedEncodingContainer(
            KeyedCBOREncodingContainer<NestedKey, KeyBuffer.Keyed>(
                parent: storage.withKey(key),
                context: context.appending(key)
            )
        )
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
        UnkeyedCBOREncodingContainer<KeyBuffer.Keyed>(
            parent: storage.withKey(key),
            context: context.appending(key)
        )
    }

    mutating func superEncoder() -> any Encoder {
        fatalError("Unimplemented")
    }

    mutating func superEncoder(forKey key: Key) -> any Encoder {
        fatalError("Unimplemented")
    }
}

// MARK: - Key Buffer

extension KeyedCBOREncodingContainer {
    final class KeyBuffer {
        init(parent: ParentStorage, context: EncodingContext) {
            self.parent = parent
            self.context = context
            map.reserveCapacity(4)
            intMap.reserveCapacity(4)
        }

        private let parent: ParentStorage
        private let context: EncodingContext
        private var map: [String: EncodingOptimizer] = [:]
        private var intMap: [Int: EncodingOptimizer] = [:]

        func withKey<T: CodingKey>(_ key: T) -> Keyed {
            Keyed(storage: Unmanaged.passUnretained(self), key: key, forceStringKeys: context.options.forceStringKeys)
        }

        enum KeyType {
            case string(String)
            case int(Int)
        }

        struct Keyed: TemporaryEncodingStorage {
            let storage: Unmanaged<KeyBuffer>
            let key: KeyType

            init<T: CodingKey>(storage: Unmanaged<KeyBuffer>, key: T, forceStringKeys: Bool) {
                self.storage = storage
                if let intKey = key.intValue, !forceStringKeys {
                    self.key = .int(intKey)
                } else {
                    self.key = .string(key.stringValue)
                }
            }

            @inlinable
            func register(_ optimizer: EncodingOptimizer) {
                switch key {
                case .string(let key):
                    storage.takeUnretainedValue().map[key] = optimizer
                case .int(let key):
                    storage.takeUnretainedValue().intMap[key] = optimizer
                }
            }
        }

        deinit {
            if !intMap.isEmpty && !context.options.forceStringKeys {
                parent.register(KeyedOptimizer(value: intMap))
            } else {
                parent.register(KeyedOptimizer(value: map))
            }
        }
    }
}
