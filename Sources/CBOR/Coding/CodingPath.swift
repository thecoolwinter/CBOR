//
//  CodingPath.swift
//  CBOR
//
//  Created by Khan Winter on 8/17/25.
//

/// Reconstructible coding path.
enum CodingPath {
    case root
    indirect case child(key: CodingKey, parent: CodingPath)

    var expanded: [CodingKey] {
        switch self {
        case .root: return []
        case let .child(key: key, parent: parent):
            return parent.expanded + CollectionOfOne(key)
        }
    }
}
