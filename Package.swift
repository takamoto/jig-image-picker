// swift-tools-version: 5.10
import PackageDescription

let argumentParser: Target.Dependency = .product(
  name: "ArgumentParser", package: "swift-argument-parser")

let package = Package(
  name: "jig-image-picker",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.2"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.0"),
  ],
  targets: [
    .target(
      name: "JigImagePickerCore",
      dependencies: [.product(name: "Yams", package: "Yams"), argumentParser],
      path: "Sources/jig-image-picker-core"),
    .executableTarget(
      name: "jig-image-picker",
      dependencies: ["JigImagePickerCore", argumentParser]),
    .testTarget(
      name: "JigImagePickerCoreTests",
      dependencies: [
        "JigImagePickerCore", .product(name: "Yams", package: "Yams"), argumentParser,
      ],
      path: "Tests/jig-image-picker-core"),
  ]
)
