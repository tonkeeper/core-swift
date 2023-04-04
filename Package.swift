// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WalletCoreSwift",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "WalletCoreSwift", targets: ["WalletCoreSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tonkeeper/ton-swift", .exact("1.0.0"))
    ],
    targets: [
        .target(
            name: "WalletCoreSwift",
            dependencies: [
                .product(name: "TonSwift", package: "ton-swift"),
            ]),
//        .testTarget(
//            name: "WalletCoreSwiftTests",
//            dependencies: [
//                .byName(name: "TonSwift"),
//            ]),
    ]
)
