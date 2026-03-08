// swift-tools-version: 5.9
// Copyright (c) 2026 okooo5km(十里). All rights reserved.
// Licensed under the MIT License.

import PackageDescription

let useLocalFramework = true

let package = Package(
  name: "PNGOptimKit",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
  ],
  products: [
    .library(
      name: "PNGOptimKit",
      targets: ["PNGOptimKit"]
    ),
  ],
  targets: [
    // Prebuilt Rust static library
    useLocalFramework
      ? .binaryTarget(
        name: "PNGOptimCore",
        path: "PNGOptimCore.xcframework"
      )
      : .binaryTarget(
        name: "PNGOptimCore",
        url:
          "https://github.com/okooo5km/pngoptim-swift/releases/download/v0.1.0/PNGOptimCore.xcframework.zip",
        checksum: "0000000000000000000000000000000000000000000000000000000000000000"
      ),
    // C header + modulemap bridge
    .target(
      name: "CPNGOptim",
      dependencies: ["PNGOptimCore"],
      path: "Sources/CPNGOptim"
    ),
    // Public Swift API
    .target(
      name: "PNGOptimKit",
      dependencies: ["CPNGOptim"],
      path: "Sources/PNGOptimKit"
    ),
    .testTarget(
      name: "PNGOptimKitTests",
      dependencies: ["PNGOptimKit"],
      path: "Tests/PNGOptimKitTests",
      resources: [.copy("Fixtures")]
    ),
  ]
)
