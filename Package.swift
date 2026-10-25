// swift-tools-version: 5.9
// Copyright (c) 2026 okooo5km(十里). All rights reserved.
// Licensed under the MIT License.

import PackageDescription

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
    .binaryTarget(
      name: "PNGOptimCore",
      url:
        "https://github.com/okooo5km/pngoptim-swift/releases/download/v0.5.5/PNGOptimCore.xcframework.zip",
      checksum: "56ee7ccd5941df86f026e1c2664ec14fd4b333ae90a7fe0c073772c1c30b33ae"
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
