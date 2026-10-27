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
        "https://github.com/okooo5km/pngoptim-swift/releases/download/v0.6.2/PNGOptimCore.xcframework.zip",
      checksum: "9350fbd7162f7acd0147b8dcd16b3702b833708c69b38423e89e182e3f006c3d"
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
