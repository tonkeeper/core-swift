// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WalletCore",
    platforms: [
        .macOS(.v12), .iOS(.v13)
    ],
    products: [
        .library(name: "WalletCore", targets: ["WalletCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tonkeeper/ton-swift", .exact("1.0.0")),
        .package(url: "https://github.com/tonkeeper/ton-api-swift", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "WalletCore",
            dependencies: [
                .product(name: "TonSwift", package: "ton-swift"),
                .product(name: "TonAPI", package: "ton-api-swift"),
            ]),
        .testTarget(
            name: "WalletCoreTests",
            dependencies: [
                .byName(name: "WalletCore"),
            ]),
    ]
)
