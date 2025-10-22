//
//  UnkeyedCBOREncodingContainer.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

struct UnkeyedCBOREncodingContainer<ParentStorage: TemporaryEncodingStorage>: UnkeyedEncodingContainer {
    private let storage: KeyBuffer
    private let context: EncodingContext

    var codingPath: [CodingKey] { context.codingPath }
    var count: Int { storage.count }

    init(parent: ParentStorage, context: EncodingContext) {
        self.storage = KeyBuffer(parent: parent)
        self.context = context
    }

    private func nextContext() -> EncodingContext {
        context.appending(UnkeyedCodingKey(intValue: count))
    }

    func encode<T: Encodable>(_ value: T) throws {
        try SingleValueCBOREncodingContainer(parent: storage.forAppending(), context: nextContext()).encode(value)
    }

    mutating func encodeNil() throws {
        storage.forAppending().register(NilOptimizer())
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> {
        KeyedEncodingContainer(KeyedCBOREncodingContainer(parent: storage.forAppending(), context: nextContext()))
    }

    mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
        UnkeyedCBOREncodingContainer<KeyBuffer.Indexed>(
            parent: storage.forAppending(),
            context: nextContext()
        )
    }

    mutating func superEncoder() -> any Encoder {
        fatalError("Unimplemented")
    }
}

extension UnkeyedCBOREncodingContainer {
    private final class KeyBuffer {
        var count: Int { items.count }

        private let parent: ParentStorage
        private var items: [EncodingOptimizer] = []

        init(parent: ParentStorage) {
            self.parent = parent
            self.items = []
            items.reserveCapacity(10)
        }

        func forAppending() -> Indexed {
            items.append(EmptyOptimizer())
            return Indexed(parent: Unmanaged.passUnretained(self), index: items.count - 1)
        }

        struct Indexed: TemporaryEncodingStorage {
            let parent: Unmanaged<KeyBuffer>
            let index: Int

            func register(_ optimizer: EncodingOptimizer) {
                parent.takeUnretainedValue().items[index] = optimizer
            }
        }

        deinit {
            parent.register(UnkeyedOptimizer(value: items))
        }
    }

}
