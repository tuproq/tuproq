// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "tuproq",
    products: [
        .library(name: "Tuproq", targets: ["Tuproq"])
    ],
    dependencies: [
        .package(name: "tuproq-postgresql", url: "https://github.com/tuproq/postgresql.git", .branch("master"))
    ],
    targets: [
        .target(name: "Tuproq", dependencies: [
            .product(name: "PostgreSQL", package: "tuproq-postgresql")
        ]),
        .testTarget(name: "TuproqTests", dependencies: [
            .target(name: "Tuproq")
        ])
    ],
    swiftLanguageVersions: [.v5]
)
