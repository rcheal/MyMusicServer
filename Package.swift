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
            url: "file:///Users/bob/Developer/MyMusic/MusicMetadata",
            from: "1.0.0"),
        .package(
            name: "SQLite",
            url: "https://github.com/stephencelis/SQLite.swift.git",
            from: "0.13.1")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .byName(name: "MusicMetadata"),
                .byName(name: "SQLite")
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
                    .byName(name: "SQLite")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
            .byName(name: "MusicMetadata"),
            .byName(name: "SQLite")
        ])
    ]
)
