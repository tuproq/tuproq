// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "tuproq",
    products: [
        .library(name: "Tuproq", targets: ["Tuproq"])
    ],
    targets: [
        .target(name: "Tuproq"),
        .testTarget(
            name: "TuproqTests",
            dependencies: [
                .target(name: "Tuproq")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
