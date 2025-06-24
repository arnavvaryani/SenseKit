// swift-tools-version: 6.0


import PackageDescription

let package = Package(
  name: "SenseKit",
  platforms: [.iOS(.v17), .macOS(.v15)],
  products: [
    .library(name: "SenseKit", targets: ["SenseKit"]),
  ],
  targets: [
    .target(
      name: "SenseKit",
      dependencies: [],
    ),
    .testTarget(
      name: "SenseKitTests",
      dependencies: ["SenseKit"],
    ),
  ]
)
