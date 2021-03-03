// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MyMusicServer",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(
            name: "MusicMetadata",
            url: "https://github.com/rcheal/MusicMetadata.git",
            from: "1.0.0"),
        .package(
            name: "GRDB",
            url: "https://github.com/groue/GRDB.swift.git",
            from: "5.2.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .byName(name: "MusicMetadata"),
                .byName(name: "GRDB")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(name: "Run", dependencies: [
                    .target(name: "App"),
                    .byName(name: "MusicMetadata"),
                    .byName(name: "GRDB")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
            .byName(name: "MusicMetadata"),
            .byName(name: "GRDB")
        ])
    ]
)
