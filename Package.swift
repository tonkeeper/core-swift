// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WalletCore",
    platforms: [
        .macOS(.v12), .iOS(.v13)
    ],
    products: [
        .library(name: "WalletCore", targets: ["WalletCore"]),
        .library(name: "WalletCoreDynamic", type: .dynamic, targets: ["WalletCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tonkeeper/ton-swift", branch: "feature/nft_transfer"),
        .package(url: "https://github.com/tonkeeper/ton-api-swift", from: "0.1.1")
    ],
    targets: [
        .target(
            name: "WalletCore",
            dependencies: [
                .product(name: "TonSwift", package: "ton-swift"),
                .product(name: "TonAPI", package: "ton-api-swift"),
                .product(name: "TonStreamingAPI", package: "ton-api-swift"),
                .product(name: "StreamURLSessionTransport", package: "ton-api-swift"),
                .product(name: "EventSource", package: "ton-api-swift")
            ],
            resources: [.copy("PackageResources")]),
        .testTarget(
            name: "WalletCoreTests",
            dependencies: [
                .byName(name: "WalletCore"),
            ],
            resources: [.copy("PackageResources")])
    ]
)
