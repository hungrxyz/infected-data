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
        .package(url: "https://github.com/dehesa/CodableCSV.git", .upToNextMinor(from: "0.6.3"))
    ],
    targets: [
        .target(
            name: "Scalpel",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CodableCSV", package: "CodableCSV")
            ],
            resources: [
                .process("CBS/Gebieden_in_Nederland_2020_07122020_202646.csv"),
                .process("Vaccinations/vaccinations_administered.csv"),
                .process("Vaccinations/vaccinations_deliveries.csv"),
                .process("HomeAdmissions/luscii_home_admissions.csv")
            ]
        ),
        .testTarget(
            name: "ScalpelTests",
            dependencies: ["Scalpel"]
        )
    ]
)
