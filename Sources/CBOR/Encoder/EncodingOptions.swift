//
//  EncodingOptions.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

/// Options that determine the behavior of ``CBOREncoder``.
public struct EncodingOptions {
    /// Force encoded maps to use string keys even when integer keys are available.
    public let forceStringKeys: Bool

    /// Methods for encoding dates.
    public enum DateStrategy {
        /// Encodes dates as `ISO8601` date strings under tag `0`.
        case string
        /// Encodes dates as an epoch date using a Float value. Loses precision at the benefit of half the size
        /// of a double.
        case float
        /// Encodes dates as an epoch date using a Double value.
        /// Highest precision.
        case double
    }

    /// Determine how to encode dates.
    public let dateEncodingStrategy: DateStrategy

    /// Different strategies for encoding tagged items.
    public enum TagStrategy {
        /// Encode all tagged items. Default.
        case accept
        /// DAG mode option. Reject all tagged items (UUIDs). If possible, encoder uses an alternative encoding
        /// method. Otherwise, throws an encoding error.
        case dagMode
    }

    /// Determine how to encode tagged items.
    public let taggedItemsStrategy: TagStrategy

    /// Force the encoder to encode all floating point numbers as 64-bit double values.
    public let forceDoubleLengthEncoding: Bool

    /// DAG mode option. Reject all Infinity and NaN values for floating-point numbers (`Double`, `Float`).
    public let rejectInfAndNan: Bool

    /// Initialize new encoding options.
    /// - Parameters:
    ///   - forceStringKeys: Force encoded maps to use string keys even when integer keys are available.
    ///   - useStringDates: See ``dateEncodingStrategy`` and ``DateStrategy``.
    ///   - taggedItemsStrategy: See ``taggedItemsStrategy`` and ``TagStrategy``.
    ///   - forceDoubleLengthEncoding: Encode all floating point numbers as 64-bit double values.
    ///   - rejectInfAndNan: DAG mode option. Reject all Infinity and NaN values for floating-point numbers (`Double`,
    ///                      `Float`).
    public init(
        forceStringKeys: Bool,
        dateEncodingStrategy: DateStrategy,
        taggedItemsStrategy: TagStrategy,
        forceDoubleLengthEncoding: Bool,
        rejectInfAndNan: Bool
    ) {
        self.forceStringKeys = forceStringKeys
        self.dateEncodingStrategy = dateEncodingStrategy
        self.taggedItemsStrategy = taggedItemsStrategy
        self.forceDoubleLengthEncoding = forceDoubleLengthEncoding
        self.rejectInfAndNan = rejectInfAndNan
    }

    static func dag(dateEncodingStrategy: DateStrategy) -> EncodingOptions {
        EncodingOptions(
            forceStringKeys: true,
            dateEncodingStrategy: dateEncodingStrategy,
            taggedItemsStrategy: .dagMode,
            forceDoubleLengthEncoding: true,
            rejectInfAndNan: true
        )
    }
}
