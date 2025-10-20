//
//  SingleValueCBOREncodingContainer.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct SingleValueCBOREncodingContainer<Storage: TemporaryEncodingStorage>: Encoder {
    let parent: Storage
    let context: EncodingContext

    var userInfo: [CodingUserInfoKey: Any] = [:]
    var options: EncodingOptions { context.options }
    var codingPath: [CodingKey] { context.codingPath }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        .init(KeyedCBOREncodingContainer(parent: parent, context: context))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        UnkeyedCBOREncodingContainer(parent: parent, context: context)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        self
    }
}

extension SingleValueCBOREncodingContainer: SingleValueEncodingContainer {
    func encodeNil() throws {
        parent.register(NilOptimizer())
    }

    func encode(_ value: String) throws {
        parent.register(StringOptimizer(value: value))
    }

    func encode(_ value: Bool) throws {
        parent.register(BoolOptimizer(value: value))
    }

    func encode(_ value: Double) throws {
        if options.rejectInfAndNan && (value.isInfinite || value.isNaN) {
            throw EncodingError.invalidValue(
                value,
                context.error("Configured to reject Inf and NaN values. Found Infinite or NaN floating point value.")
            )
        }
        parent.register(DoubleOptimizer(value: value))
    }

    func encode(_ value: Float) throws {
        if options.forceDoubleLengthEncoding {
            try encode(Double(value))
        } else {
            parent.register(FloatOptimizer(value: value))
        }
    }

    func encode<T>(_ value: T) throws where T: Encodable, T: FixedWidthInteger {
        parent.register(IntOptimizer(value: value))
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        // I hate this conditional cast, but Swift forces us to do this because Codable can't implement a specialized
        // function for any type, only the standard library types. This is the same method Foundation uses to detect
        // special encoding cases. It's still lame.
        switch value {
        case let value as Date:
            try _encodeDate(value)
        case let value as Data:
            parent.register(ByteStringOptimizer(value: value))
        case let value as TaggedCBORItem:
            try _encodeTaggedItem(value, T.self)
// #if canImport(Float16)
//        case let value as Float16:
//            parent.register(Float16Optimizer(value: value))
// #endif
        default:
            try value.encode(to: self)
        }
    }

    func _encodeDate(_ value: Date) throws {
        switch options.dateEncodingStrategy {
        case .string:
            if options.taggedItemsStrategy == .dagMode {
                parent.register(StringDateOptimizer(value: value).optimizer)
            } else {
                parent.register(StringDateOptimizer(value: value))
            }
        case .float:
            if options.taggedItemsStrategy == .dagMode {
                parent.register(EpochFloatDateOptimizer(value: value).optimizer)
            } else {
                parent.register(EpochFloatDateOptimizer(value: value))
            }
        case .double:
            if options.taggedItemsStrategy == .dagMode {
                parent.register(EpochDoubleDateOptimizer(value: value).optimizer)
            } else {
                parent.register(EpochDoubleDateOptimizer(value: value))
            }
        }
    }

    func _encodeTaggedItem<T: Encodable>(_ value: TaggedCBORItem, _ type: T.Type) throws {
        let tag = value.__staticTagLookup
        guard options.taggedItemsStrategy == .accept || tag == 42 else {
            throw EncodingError.invalidValue(
                value,
                // swiftlint:disable:next line_length
                context.error("In DAG mode, all tagged items are rejected except tag 42. UUIDs are encoded as a tagged value by default. Override `encode` for your type and encode UUID with a different representation.")
            )
        }
        parent.register(try TaggedItemOptimizer(value: value, context: context))
    }
}
