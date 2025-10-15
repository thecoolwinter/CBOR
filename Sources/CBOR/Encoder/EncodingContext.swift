//
//  EncodingContext.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

/// Encoding context, shared between all internal encoders, containers, etc. during encoding process.
struct EncodingContext {
    let options: EncodingOptions
    let path: CodingPath

    var codingPath: [CodingKey] { path.expanded }

    init(options: EncodingOptions) {
        self.options = options
        self.path = .root
    }

    private init(options: EncodingOptions, path: CodingPath) {
        self.options = options
        self.path = path
    }

    func appending<Key: CodingKey>(_ key: Key) -> EncodingContext {
        EncodingContext(options: options, path: .child(key: key, parent: path))
    }

    func error(_ description: String = "", error: Error? = nil) -> EncodingError.Context {
        .init(codingPath: codingPath, debugDescription: description, underlyingError: error)
    }
}
