// swift-tools-version: 5.9
// Copyright (c) 2026 okooo5km(十里). All rights reserved.
// Licensed under the MIT License.

import PackageDescription

let useLocalFramework = false

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
          "https://github.com/okooo5km/pngoptim-swift/releases/download/v0.4.1/PNGOptimCore.xcframework.zip",
        checksum: "e9311e55a10a5cf4be3a2ecb5b0ab30a0173e00f4527d550d7dbed069bece8c4"
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
