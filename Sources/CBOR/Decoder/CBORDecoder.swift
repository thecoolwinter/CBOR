//
//  CBORDecoder.swift
//  CBOR
//
//  Created by Khan Winter on 8/20/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Decodes ``Decodable`` objects from CBOR data.
///
/// This type can be reused efficiently for multiple deserialization operations. Use the ``decode(_:from:)`` method
/// to decode data.
///
/// To configure decoding behavior, pass options to the ``init(rejectIndeterminateLengths:)`` method or modify
/// the ``options`` variable.
public struct CBORDecoder {
    /// The options that determine decoding behavior.
    public var options: DecodingOptions

    /// Create a new CBOR decoder.
    ///
    /// All parameters match flags in ``DecodingOptions``.
    public init(
        rejectIndeterminateLengths: Bool = true,
        recursionDepth: Int = 50,
        rejectIntKeys: Bool = false,
        rejectUnorderedMap: Bool = false,
        rejectUndefined: Bool = false,
        rejectNaN: Bool = false,
        rejectInf: Bool = false,
        singleTopLevelItem: Bool = false,
    ) {
        self.options = DecodingOptions(
            rejectIndeterminateLengths: rejectIndeterminateLengths,
            recursionDepth: recursionDepth,
            rejectIntKeys: rejectIntKeys,
            rejectUnorderedMap: rejectUnorderedMap,
            rejectUndefined: rejectUndefined,
            rejectNaN: rejectNaN,
            rejectInf: rejectInf,
            singleTopLevelItem: singleTopLevelItem
        )
    }

    /// Create a new CBOR decoder
    /// - Parameter options: The decoding options to use.
    public init(options: DecodingOptions) {
        self.options = options
    }

    /// Decodes the given type from CBOR binary data.
    /// - Parameters:
    ///   - type: The decodable type to deserialize.
    ///   - data: The CBOR data to decode from.
    /// - Returns: An instance of the decoded type.
    /// - Throws: A ``DecodingError`` with context and a debug description for a failed deserialization operation.
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try data.withUnsafeBytes {
                let data = $0[...]
                let reader = DataReader(data: data)
                let scanner = CBORScanner(data: reader, options: options)
                let results = try scanner.scan()

                guard !results.isEmpty else {
                    throw ScanError.unexpectedEndOfData
                }

                let context = DecodingContext(options: options, results: results)
                let region = results.load(at: 0)

                return try SingleValueCBORDecodingContainer(context: context, data: region).decode(T.self)
            }
        } catch {
            if let error = error as? ScanError {
                throw error.decodingError()
            } else {
                throw error
            }
        }
    }

    /// Decodes multiple instances of the given type from CBOR binary data.
    ///
    /// Some BLOBs are made up of multiple CBOR-encoded datas concatenated without valid CBOR dividers (eg in an array
    /// container). This method decodes that kind of data. It will attempt to decode an instance of the given type,
    /// once done, if there's more data, it will continue to attempt to decode more instances.
    ///
    /// - Parameters:
    ///   - type: The decodable type to deserialize.
    ///   - data: The CBOR data to decode from.
    /// - Returns: An instance of the decoded type.
    /// - Throws: A ``DecodingError`` with context and a debug description for a failed deserialization operation.
    public func decodeMultiple<T: Decodable>(_ type: T.Type, from data: Data) throws -> [T] {
        do {
            return try data.withUnsafeBytes {
                let data = $0[...]
                let reader = DataReader(data: data)
                let scanner = CBORScanner(data: reader, options: options)
                let results = try scanner.scan()

                guard !results.isEmpty else {
                    throw ScanError.unexpectedEndOfData
                }

                let context = DecodingContext(options: options, results: results)
                var nextRegion: DataRegion? = results.load(at: 0)

                var accumulator: [T] = []

                while let region = nextRegion {
                    let value = try SingleValueCBORDecodingContainer(context: context, data: region).decode(T.self)
                    accumulator.append(value)
                    let nextMapIndex = results.siblingIndex(region.mapOffset)
                    if nextMapIndex < results.count {
                        nextRegion = results.load(at: results.siblingIndex(region.mapOffset))
                    } else {
                        nextRegion = nil
                    }
                }

                return accumulator
            }
        } catch {
            if let error = error as? ScanError {
                throw error.decodingError()
            } else {
                throw error
            }
        }
    }
}
