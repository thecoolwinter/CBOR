//
//  CommonTags.swift
//  SwiftCBOR
//
//  Created by Khan Winter on 8/17/25.
//

/// Some common tags for encoding/decoding specifically formatted data such as Dates and UUIDs.
enum CommonTags: UInt {
    case stringDate = 0
    case epochDate = 1
    case uuid = 37
    case cid = 42
}
