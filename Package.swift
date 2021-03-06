// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Scalpel",
    products: [
        .executable(name: "scalpel", targets: ["Scalpel"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/dehesa/CodableCSV.git", .upToNextMinor(from: "0.6.3")),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", .upToNextMinor(from: "2.3.0"))
    ],
    targets: [
        .target(
            name: "Scalpel",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CodableCSV", package: "CodableCSV"),
                .product(name: "SwiftSoup", package: "SwiftSoup")
            ],
            resources: [
                .process("CBS/Gebieden_in_Nederland_2020_07122020_202646.csv"),
                .process("Vaccinations/vaccinations_administered.csv"),
                .process("Vaccinations/vaccinations_deliveries.csv")
            ]
        ),
        .testTarget(
            name: "ScalpelTests",
            dependencies: ["Scalpel"]
        )
    ]
)
