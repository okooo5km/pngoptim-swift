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
          "https://github.com/okooo5km/pngoptim-swift/releases/download/v0.3.1/PNGOptimCore.xcframework.zip",
        checksum: "3a996b676fe1006b0a74c7981b6011282b8fd65733d1bba87967623ffe106b0e"
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
