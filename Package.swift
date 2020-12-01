// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftDuxNavigation",
    platforms: [
      .iOS(.v14),
      .macOS(.v11),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftDuxNavigation",
            targets: ["AppNavigation"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
      .package(url: "https://github.com/StevenLambion/SwiftDux.git", from: "2.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "AppNavigation",
            dependencies: ["SwiftDux"]),
        .testTarget(
            name: "SwiftDuxNavigationTests",
            dependencies: ["AppNavigation"]),
    ]
)
