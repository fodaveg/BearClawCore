// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BearClawCore",
    platforms: [
        .macOS(.v14), // o la versión que necesites
        .iOS(.v17),      // o la versión que necesites
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BearClawCore",
            targets: ["BearClawCore"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BearClawCore"),
        .testTarget(
            name: "BearClawCoreTests",
            dependencies: ["BearClawCore"]),
    ]
)
