//
//  TagRecursionTests.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@testable import CBOR

@Suite
struct TagRecursionTests {
    @Test
    func scannerRejectsNestedTagsBeyondRecursionLimit() {
        let data = nestedTags(100)
        let options = DecodingOptions(recursionDepth: 50)

        do {
            try data.withUnsafeBytes {
                let reader = DataReader(data: $0[...])
                _ = try CBORScanner(data: reader, options: options).scan()
            }
            Issue.record("Expected the scanner to reject tag nesting beyond recursionDepth")
        } catch {
            #expect(isRecursionLimitError(error))
        }
    }

    @Test
    func decoderRejectsNestedTagsBeyondRecursionLimit() {
        let data = nestedTags(100)

        do {
            _ = try CBORDecoder(recursionDepth: 50).decode(Int.self, from: data)
            Issue.record("Expected the decoder to reject tag nesting beyond recursionDepth")
        } catch {
            #expect(isRecursionLimitError(error))
        }
    }

    @Test
    func decodeMultipleRejectsNestedTagsBeyondRecursionLimit() {
        let data = nestedTags(100)

        do {
            _ = try CBORDecoder(recursionDepth: 50).decodeMultiple(Int.self, from: data)
            Issue.record("Expected decodeMultiple to reject tag nesting beyond recursionDepth")
        } catch {
            #expect(isRecursionLimitError(error))
        }
    }

    private func nestedTags(_ count: Int) -> Data {
        Data(Array(repeating: UInt8(0xC6), count: count) + [0xF6])
    }

    private func isRecursionLimitError(_ error: Error) -> Bool {
        if let error = error as? ScanError {
            if case .recursionLimit = error {
                return true
            }
            return false
        }

        guard case .dataCorrupted(let context) = error as? DecodingError else {
            return false
        }

        if let underlying = context.underlyingError as? ScanError,
           case .recursionLimit = underlying {
            return true
        }

        return context.debugDescription.contains("Recursion depth limit exceeded")
    }
}
