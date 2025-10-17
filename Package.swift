// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftAnyCodable",
	platforms: [
		.iOS(.v13),
		.macOS(.v10_15),
		.tvOS(.v13),
	],
    products: [
        .library(
            name: "SwiftAnyCodable",
			targets: ["SwiftAnyCodable"]
		),
    ],
    targets: [
        .target(
			name: "SwiftAnyCodable"
		),
        .testTarget(
            name: "SwiftAnyCodableTests",
            dependencies: ["SwiftAnyCodable"]
        ),
    ]
)
