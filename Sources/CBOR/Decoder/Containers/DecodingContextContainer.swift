//
//  DecodingContextContainer.swift
//  CBOR
//
//  Created by Khan Winter on 8/20/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

protocol DecodingContextContainer {
    var context: DecodingContext { get }
    var data: DataRegion { get }
}

extension DecodingContextContainer {
    var codingPath: [any CodingKey] { context.codingPath }
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    /// Check the next type on the data stack.
    /// - Parameter type: The type to check for.
    @discardableResult
    func checkType<T>( _ types: MajorType..., arguments: UInt8..., as: T.Type) throws -> UInt8 {
        guard types.contains(data.type) else {
            throw DecodingError.typeMismatch(T.self, context.error("Unexpected type found: \(data.type)."))
        }

        let argument = data.argument // Already checked with type()
        guard arguments.contains(argument) else {
            throw DecodingError.dataCorrupted(context.error("Unexpected argument \(argument) for \(T.self) value."))
        }
        return argument
    }

    /// Check the next type on the data stack.
    /// - Parameter type: The type to check for.
    func checkType<T>(_ types: MajorType..., forType: T.Type) throws {
        guard types.contains(data.type) else {
            throw DecodingError.typeMismatch(T.self, context.error("Unexpected type found: \(data.type)."))
        }
    }

    /// Check an available tag value by reading either the argument or the next int value.
    func checkTag<T>(_ tag: UInt, forType: T.Type) throws {
        let tagValue = try data.readInt(as: UInt.self)
        guard tagValue == tag else {
            throw DecodingError.typeMismatch(
                T.self,
                context.error("Unexpected tag found: \(tagValue), expected \(tag) for \(T.self)")
            )
        }
    }
}
