// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WalletCore",
    platforms: [
        .macOS(.v11), .iOS(.v14)
    ],
    products: [
        .library(name: "WalletCore", targets: ["WalletCore"]),
        .library(name: "WalletCoreDynamic", type: .dynamic, targets: ["WalletCore"]),
        .library(name: "WalletCore-Core", targets: ["WalletCore-Core"])
    ],
    dependencies: [
        .package(url: "https://github.com/tonkeeper/ton-swift", branch: "main"),
        .package(url: "https://github.com/tonkeeper/ton-api-swift", from: "0.1.1"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "0.3.0"))
    ],
    targets: [
        .target(
            name: "WalletCore",
            dependencies: [
                .product(name: "TonSwift", package: "ton-swift"),
                .product(name: "TonAPI", package: "ton-api-swift"),
                .product(name: "TonStreamingAPI", package: "ton-api-swift"),
                .product(name: "StreamURLSessionTransport", package: "ton-api-swift"),
                .product(name: "EventSource", package: "ton-api-swift"),
                .target(name: "TonConnectAPI")
            ],
            resources: [.copy("PackageResources")]),
        .target(name: "WalletCore-Core",
                dependencies: [
                    .product(name: "TonSwift", package: "ton-swift")
                ]),
        .testTarget(name: "WalletCore-CoreTests",
                    dependencies: ["WalletCore-Core"]),
        .target(name: "TonConnectAPI",
                dependencies: [
                    .product(
                        name: "OpenAPIRuntime",
                        package: "swift-openapi-runtime"
                    ),
                ],
                path: "Packages/TonConnectAPI",
                sources: ["Sources"]
               ),
    ]
)
