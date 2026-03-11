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
          "https://github.com/okooo5km/pngoptim-swift/releases/download/v0.4.1/PNGOptimCore.xcframework.zip",
        checksum: "e38cab60c293768c39f568827d919293c1d03ce0c15dc54dfb63f479c49d8812"
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
