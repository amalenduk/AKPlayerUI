// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AKPlayerUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18)
    ],
    products: [
        .library(
            name: "AKPlayerUI",
            targets: ["AKPlayerUI"]
        )
    ],
    dependencies: [
        .package(path: "../AKPlayer")
    ],
    targets: [
        .target(
            name: "AKPlayerUI",
            dependencies: [
                .product(name: "AKPlayer", package: "AKPlayer")
            ]
        ),
        .testTarget(
            name: "AKPlayerUITests",
            dependencies: ["AKPlayerUI"]
        )
    ]
)
