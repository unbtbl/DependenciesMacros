// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "UnbeatableDependenciesMacros",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "UnbeatableDependenciesMacros",
            targets: ["UnbeatableDependenciesMacros"]
        )
    ],
    dependencies: [
        // 🤖
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),

        // 🔌
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.1.0"),

        // 🧐
        .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.2.1"),

    ],
    targets: [
        .target(
            name: "UnbeatableDependenciesMacros",
            dependencies: [
                .target(name: "UnbeatableDependenciesMacrosPlugin"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .macro(
            name: "UnbeatableDependenciesMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "UnbeatableDependenciesMacrosTests",
            dependencies: [
                .target(name: "UnbeatableDependenciesMacrosPlugin"),
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ]
        ),
    ]
)
