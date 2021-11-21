// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "tuproq",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
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
