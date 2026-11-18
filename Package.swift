// swift-tools-version: 6.4

import PackageDescription

let package = Package(
	name: "NetDSL",
	platforms: [
		.iOS(.v15),
		.macOS(.v12),
	],
	products: [
		.library(name: "NetDSL", targets: ["NetDSL"]),
	],
	targets: [
		.target(
			name: "NetDSL",
			swiftSettings: [
				.enableUpcomingFeature("ApproachableConcurrency"),
			]
		),
		.testTarget(
			name: "NetDSLTests",
			dependencies: ["NetDSL"],
			swiftSettings: [
				.enableUpcomingFeature("ApproachableConcurrency"),
			]
		),
	]
)
