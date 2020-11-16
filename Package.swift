// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Artemisia",
    platforms: [.iOS(.v10)],
    products: [
        .library(
            name: "Artemisia",
            targets: ["Artemisia"]),
    ],
    dependencies: [
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "MosquittoC", dependencies: [], cSettings:[.define("WITH_THREADING")]),
        .target(
            name: "Artemisia",
            dependencies: ["MosquittoC"]),
        .testTarget(
            name: "ArtemisiaTests",
            dependencies: ["Artemisia"]),
    ]
)
