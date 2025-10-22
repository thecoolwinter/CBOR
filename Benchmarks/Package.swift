// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Benchmarks",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
        .package(path: ".."),
        .package(url: "https://github.com/valpackett/SwiftCBOR.git", branch: "master"),
    ],
    targets: [
        .executableTarget(
            name: "Encoding",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                "CBOR",
                .product(name: "SwiftCBOR", package: "SwiftCBOR"),
            ],
            path: "Benchmarks/Encoding",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),

        .executableTarget(
            name: "Decoding",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                "CBOR",
                .product(name: "SwiftCBOR", package: "SwiftCBOR"),
            ],
            path: "Benchmarks/Decoding",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        ),
    ]
)
