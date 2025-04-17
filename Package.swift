// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ConceptKit",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "ConceptKit",
            targets: ["ConceptKit"])
    ],
    targets: [
        .target(
            name: "ConceptKit",
            dependencies: []),
        .testTarget(
            name: "ParserTests",
            dependencies: ["ConceptKit"]),
        .testTarget(
            name: "ResolverTests",
            dependencies: ["ConceptKit"],
            resources: [
                .process("Resources")
            ])
    ]
)
