// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "CBOR",
    products: [
        .library(name: "CBOR", targets: ["CBOR"])
    ],
    dependencies: [],
    targets: [
        .target(name: "CBOR"),
        .executableTarget(
            name: "Fuzzing",
            dependencies: ["CBOR"],
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        ),
        .executableTarget(name: "ProfilingHelper", dependencies: ["CBOR"]),
        .testTarget(
            name: "CBORTests",
            dependencies: ["CBOR"]
        )
    ]
)
