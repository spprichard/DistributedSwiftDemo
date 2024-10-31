// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DistributedSwiftDemo",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        // "AI" Packages
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.18.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples/", branch: "main"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "0.1.5"),

        // Cluster Packages
        .package(url: "https://github.com/apple/swift-distributed-actors", branch: "main"),
        .package(url: "https://github.com/apple/swift-service-discovery.git", from: "1.3.0"),
        
        // Server Packages
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.12.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "DistributedSwiftDemo",
            dependencies: [
                // "AI"
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "LLM", package: "mlx-swift-examples"),
                .product(name: "Transformers", package: "swift-transformers"),
                
                // Cluster
                .product(name: "DistributedCluster", package: "swift-distributed-actors"),
                .product(name: "ServiceDiscovery", package: "swift-service-discovery"),
                
                // Server
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
