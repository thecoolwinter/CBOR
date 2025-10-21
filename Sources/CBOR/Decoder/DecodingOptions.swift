//
//  DecodingOptions.swift
//  CBOR
//
//  Created by Khan Winter on 8/23/25.
//

/// Options that determine the behavior of ``CBORDecoder``.
public struct DecodingOptions {
    /// Set to `false` to allow indeterminate length objects to be decoded.
    /// `true` by default.
    ///
    /// For deterministic encoding, this **must** be enabled.
    public var rejectIndeterminateLengths: Bool

    /// Maximum recursion depth.
    public var recursionDepth: Int = 50

    /// Reject maps with non-string keys..
    public var rejectIntKeys: Bool

    /// Reject maps whose keys are out of order.
    public var rejectUnorderedMap: Bool

    /// Reject the `undefined` simple value (`23`).
    public var rejectUndefined: Bool

    /// Enable to reject decoded `NaN` floating point values.
    public var rejectNaN: Bool

    /// Enable to reject decoded infinite floating point values.
    public var rejectInf: Bool

    /// Require that CBOR data encapsulates the *entire* data object being decoded.
    /// When true, throws a decoding error if data is left over after scanning for valid CBOR structure, or if there
    /// are multiple top-level objects.
    public var singleTopLevelItem: Bool

    /// Create a new options object.
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
        self.rejectIndeterminateLengths = rejectIndeterminateLengths
        self.recursionDepth = recursionDepth
        self.rejectIntKeys = rejectIntKeys
        self.rejectUnorderedMap = rejectUnorderedMap
        self.rejectUndefined = rejectUndefined
        self.rejectNaN = rejectNaN
        self.rejectInf = rejectInf
        self.singleTopLevelItem = singleTopLevelItem
    }
}
