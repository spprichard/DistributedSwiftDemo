// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DistributedSwiftDemo",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        // AI Packages
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.18.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples/", branch: "main"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "0.1.5"),

        // Cluster Packages
        .package(url: "https://github.com/apple/swift-distributed-actors", branch: "main"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-service-discovery.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "DistributedSwiftDemo",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "LLM", package: "mlx-swift-examples"),
                .product(name: "DistributedCluster", package: "swift-distributed-actors"),
                .product(name: "Transformers", package: "swift-transformers"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "ServiceDiscovery", package: "swift-service-discovery"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
