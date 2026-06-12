// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "PDFUnlocker",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PDFUnlocker", targets: ["PDFUnlocker"])
    ],
    targets: [
        .target(
            name: "PDFUnlockerCore",
            path: "Sources/PDFUnlockerCore"
        ),
        .executableTarget(
            name: "PDFUnlocker",
            dependencies: ["PDFUnlockerCore"],
            path: "Sources/PDFUnlocker"
        ),
        .testTarget(
            name: "PDFUnlockerCoreTests",
            dependencies: ["PDFUnlockerCore"],
            path: "Tests/PDFUnlockerCoreTests"
        )
    ]
)
