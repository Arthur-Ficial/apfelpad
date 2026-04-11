// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "apfelpad",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "apfelpad",
            path: "Sources",
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "./Info.plist",
                ])
            ]
        ),
        .testTarget(
            name: "ApfelPadTests",
            dependencies: [
                "apfelpad",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests"
        ),
    ]
)
