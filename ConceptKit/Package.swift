// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ConceptKit",
    platforms: [
        .macOS("10.13"), .iOS("12.0"), .tvOS("12.0"), .watchOS("4.0")
    ],
    products: [
        .library(
            name: "Core",
            targets: ["Core"])
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: []),
        .testTarget(
            name: "ParserTests",
            dependencies: ["Core"]),
        .testTarget(
            name: "ResolverTests",
            dependencies: ["Core"],
            resources: [
                .process("Resources")
            ])
    ]
)
