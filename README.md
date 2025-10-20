<p align="center">
  <img src="https://github.com/thecoolwinter/CBOR/blob/main/.github/Icon-256.png?raw=true" height="128">
  <h1 align="center">CBOR</h1>
</p>

<p align="center">
  <a aria-label="CI Status" href="" target="_blank">
    <img alt="" src="https://img.shields.io/github/actions/workflow/status/thecoolwinter/CBOR/ci.yml">
  </a>
  <a aria-label="Swift Version Compatibility" href="https://swiftpackageindex.com/thecoolwinter/CBOR" target="_blank">
    <img alt="" src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fthecoolwinter%2FCBOR%2Fbadge%3Ftype%3Dswift-versions">
  </a>
  <a aria-label="Platform Compatibility" href="https://swiftpackageindex.com/thecoolwinter/CBOR" target="_blank">
    <img alt="" src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fthecoolwinter%2FCBOR%2Fbadge%3Ftype%3Dplatforms">
  </a>
</p>

[CBOR](https://cbor.io/) is a flexible data format that emphasizes extremely small code size, small message size, and extendability. This library provides a Swift API for encoding and decoding Swift types using the CBOR serialization format. 

The motivation for this library over existing implementations is twofold: performance, and reliability. Existing community implementations do not make correct use of Swift features like `Optional` and memory safety. This library aims to be safe while still outperforming other implementations. To that end, this library has been extensively [fuzz tested](./Fuzz.md) to ensure your application never crashes due to malicious input. At the same time, this library boasts up to a *74% faster* encoding and up to *89% faster* decoding than existing implementations. See [benchmarks](#benchmarks) for more details.

## Features

- `Codable` API for familiar Swift project integration.
- Customizable encoding options, such as date and key formatting.
- Customizable decoding, with the ability to reject non-deterministic CBOR data.
- Encoder creates deterministic CBOR data by default.
  - Dictionaries are automatically sorted using a min heap for speed.
  - Duplicate map keys are removed.
  - Never creates non-deterministic collections (Strings, Byte Strings, Arrays, or Maps).
- A scan pass allows for decoding only the keys you need from an encoded object.
- Supports decoding half precision floats (Float16) as a regular Float.
- Runs on Linux, Android, and Windows using the swift-foundation project when available.
- Fuzz tested for reliability against crashes.
- Supports tagged items (will expand and add ability to inject your own tags in the future):
  - Dates
  - UUIDs
  - [CIDs](https://github.com/multiformats/cid) (tag 42)
- Flexible date parsing (tags `0` or `1` with support for any numeric value representation).
- Decoding multiple top-level objects using `decodeMultiple(_:from:)`.
- *NEW* IPLD compatible DAG-CBOR encoder for content addressable data.
- *NEW* Flexible date decoding for untagged date items encoded as strings, floating point values, or integers.

> Note: This is not a valid CBOR/CDE encoder, it merely always outputs countable collections. CBOR/CDE should be implemented in the future as it's quite similar.

## Usage

### Standard CBOR

This library utilizes Swift's `Codable` API for all (de)serialization operations. It intentionally doesn't support streaming CBOR blobs. After [installing](#installation) the package using Swift Package Manager, use the `CBOREncoder` and `CBORDecoder` types to encode to and decode from CBOR blobs, respectively.

```swift
// Encode any `Encodable` value.
let encoder = CBOREncoder()
try encoder.encode(0) // Result: 0x00
try encoder.encode([404: "Not Found"]) // Result: 0xA1190194694E6F7420466F756E64

// Decode any `Decodable` type.
let decoder = CBORDecoder()
let intValue = try decoder.decode(Int.self, from: Data([0])) // Result: 0
// Result: ["AB": 1, "A": 2]
let mapValue = try decoder.decode([String: Int].self, from: Data([162, 98, 65, 66, 1, 97, 65, 2]))
```

The encoder and decoders can be customized via the en/decoder initializers or via a `En/DecodingOptions` struct.

```swift
// Customize encoder behavior.
let encoder = CBOREncoder(
	forceStringKeys: Bool = false,
    dateEncodingStrategy: EncodingOptions.DateStrategy = .double
)
// or via the options struct
let options = EncodingOptions(/* ... */)
let encoder = CBOREncoder(options: options)

// Customize the decoder behavior, such as enforcing deterministic CBOR.
let decoder = CBORDecoder(rejectIndeterminateLengths: Bool = false)
// or via the options struct
let options = DecodingOptions(/* ... */)
let decoder = CBORDecoder(options: options)
```

### DAG-CBOR

This library also offers the ability to encode and decode DAG-CBOR data. DAG-CBOR is a superset of the CBOR spec, though very similar. This library provides a `DAGCBOREncoder` type that is automatically configured to produce compatible data. The flags it sets are also available through the `EncodingOptions` struct, but using the specialized type will ensure safety.

```swift
// !! SEE NOTE !!
let dagEncoder = DAGCBOREncoder(dateEncodingStrategy: .double)
```

To use, conform your internal CID type to ``CIDType``. Do not conform standard types like `String` or `Data` to ``CIDType``, or the encoder will attempt to encode all of those data as tagged items.
```swift
struct CID: CIDType {
    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        var data = try container.decode(Data.self)
        data.removeFirst()
        self.data = data
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Data([0x0]) + data)
    }
}
```
>   [!WARNING]
>
>   You **need** to prefix your data with the `NULL` byte when encoding. This library will not handle that for you. It is invalid DAG-CBOR encoding to not include the prefixed byte.

Now, any time the encoder finds a `CID` type it will encode it using the correct tag.
```swift
let cid = CID(bytes: [0,1,2,3,4,5,6,7,8])
let data = try DAGCBOREncoder().encode(cid)

print(data.hexString())
// Output:
// D8 2A                      # tag(42)
//    4A                      # bytes(10)
//       00000102030405060708 # "\u0000\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\b"
```
> [!NOTE]
> DAG-CBOR does not allow tagged items (besides the CID item), and thus encoding dates must be done by encoding their 'raw' value directly. This is an application specific behavior, so ensure the encoder is using the correct date encoding behavior for compatibility. By default, the encoder will encode dates as an epoch `Double` timestamp.  

## Documentation

[Documentation](https://swiftpackageindex.com/thecoolwinter/CBOR/1.1.0/documentation/cbor) is hosted on the Swift Package Index.

## Installation

You can use the Swift Package Manager to download and import the library into your project:

```swift
dependencies: [
    .package(url: "https://github.com/thecoolwinter/CBOR.git", from: "1.0.0")
]
```

Then under `targets`:

```swift
targets: [
    .target(
    	// ...
        dependencies: [
            .product(name: "CBOR", package: "CBOR")
        ]
    )
]
```

## Benchmarks

These benchmarks range from simple to complex encoding and decoding operations compared to the [SwiftCBOR](https://github.com/valpackett/SwiftCBOR) library. [Benchmarks source](./Benchmarks). Benchmarks are run on 10,000 samples and the p50 values are compared here.

### Decoding (cpu time)

| Benchmark | SwiftCBOR (ns, p50) | CBOR (ns, p50) | % Improvement |
|-----------|----------------|-----------|------------|
| Array | 23 | 7 | **70%** |
| Complex Object | 703 μs | 75 μs | **89%** |
| Date | 5,251 | 1,083 | **79%** |
| Dictionary | 17 | 5 | **71%** |
| Double | 5,295 | 1,001 | **81%** |
| Float | 5,295 | 1,000 | **81%** |
| Indeterminate String | 6,251 | 1,417 | **77%** |
| Int | 5,211 | 1,125 | **78%** |
| Int Small | 5,211 | 1,083 | **79%** |
| Simple Object | 36 | 8 | **78%** |
| String | 5,459 | 1,292 | **76%** |
| String Small | 5,291 | 1,126 | **79%** |

### Encoding (cpu time)

| Benchmark | SwiftCBOR (ns,  p50) | CBOR (ns, p50) | % Improvement |
|-----------|----------------|-----------|------------|
| Array | 669 μs | 471 μs | **30%** |
| Array Small | 7,043 | 2,917 | **59%** |
| Bool | 3,169 | 1,125 | **64%** |
| Complex Codable Object | 124 μs | 92 μs | **26%** |
| Data | 5,335 | 1,250 | **77%** |
| Data Small | 3,959 | 1000 | **75%** |
| Dictionary | 11 | 5 | **55%** |
| Dictionary Small | 7,459 | 2,959 | **60%** |
| Int | 4,001 | 1,292 | **68%** |
| Int Small | 3,833 | 1,208 | **68%** |
| Simple Codable Object | 18 | 9 | **50%** |
| String | 5,583 | 1,291 | **77%** |
| String Small | 4,041 | 1,125 | **72%** |

## Contributing

By participating in this project you agree to follow the [Contributor Code of Conduct](https://contributor-covenant.org/version/1/4/). Pull requests and issues are welcome!

## Sponsor

This project has been developed in my spare time. To keep me motivated to continue to maintain it into the future, consider [supporting my work](https://github.com/sponsors/thecoolwinter)!
