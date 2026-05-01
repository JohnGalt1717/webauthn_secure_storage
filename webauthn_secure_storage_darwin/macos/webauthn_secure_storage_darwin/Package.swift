// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "webauthn_secure_storage_darwin",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "webauthn-secure-storage-darwin", targets: ["webauthn_secure_storage_darwin"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "webauthn_secure_storage_darwin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)