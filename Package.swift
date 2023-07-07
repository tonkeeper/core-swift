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
        .package(url: "https://github.com/tonkeeper/ton-swift", branch: "feature/wallet_transfer_signing"),
        .package(url: "https://github.com/tonkeeper/ton-api-swift", branch: "feature/send_message")
    ],
    targets: [
        .target(
            name: "WalletCore",
            dependencies: [
                .product(name: "TonSwift", package: "ton-swift"),
                .product(name: "TonAPI", package: "ton-api-swift"),
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
