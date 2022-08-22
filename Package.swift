// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "tuproq",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "Tuproq", targets: ["Tuproq"])
    ],
    targets: [
        .target(name: "Tuproq"),
        .testTarget(name: "TuproqTests", dependencies: [
            .target(name: "Tuproq")
        ])
    ],
    swiftLanguageVersions: [.v5]
)
