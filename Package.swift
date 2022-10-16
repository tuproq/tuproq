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
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "Tuproq", dependencies: [
            .product(name: "Collections", package: "swift-collections")
        ]),
        .testTarget(name: "TuproqTests", dependencies: [
            .target(name: "Tuproq")
        ])
    ],
    swiftLanguageVersions: [.v5]
)
