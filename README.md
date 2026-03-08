# PNGOptimKit

Swift wrapper for the [pngoptim](https://github.com/okooo5km/pngoptim) PNG quantization engine. Provides lossy PNG compression for macOS and iOS applications via Swift Package Manager.

## Requirements

- macOS 10.15+ / iOS 13+
- Swift 5.9+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/okooo5km/pngoptim-swift.git", from: "0.1.0")
]
```

Then add `"PNGOptimKit"` to your target's dependencies.

## Usage

```swift
import PNGOptimKit

// Basic optimization
let inputData = try Data(contentsOf: imageURL)
let result = try PNGOptim.optimize(inputData)
try result.data.write(to: outputURL)

// With quality constraint
let options = PNGOptim.Options(
  quality: PNGOptim.QualityRange(60...80),
  speed: 4,
  strip: true
)
let result = try PNGOptim.optimize(inputData, options: options)

print("Saved \(result.savingsPercent)%")
print("Quality: \(result.qualityScore)")
print("Time: \(result.metrics.totalTime)s")
```

## API

### `PNGOptim.optimize(_:options:)`

Optimizes a PNG image.

- **Parameters:**
  - `data`: Raw PNG file data (`Data`)
  - `options`: Compression options (default: `.default`)
- **Returns:** `PNGOptim.Result` with optimized PNG data and metrics
- **Throws:** `PNGOptim.Error`

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `quality` | `QualityRange?` | `nil` | Quality constraint (e.g., `QualityRange(60...80)`) |
| `speed` | `UInt8` | `4` | Speed preset (1=slow/best, 11=fast) |
| `ditherLevel` | `Float` | `1.0` | Dithering level (0.0-1.0) |
| `posterize` | `UInt8` | `0` | Posterize bits (0=disabled) |
| `strip` | `Bool` | `false` | Strip metadata |
| `skipIfLarger` | `Bool` | `false` | Skip if output is larger |
| `noICC` | `Bool` | `false` | Skip ICC color-space normalization |

### Result

| Property | Type | Description |
|----------|------|-------------|
| `data` | `Data` | Optimized PNG data |
| `width` / `height` | `UInt32` | Image dimensions |
| `inputBytes` / `outputBytes` | `UInt64` | Size before/after |
| `qualityScore` | `UInt8` | Achieved quality (0-100) |
| `qualityMSE` | `Double` | Mean squared error |
| `metrics` | `Metrics` | Timing breakdown |
| `compressionRatio` | `Double` | Output/input ratio |
| `savingsPercent` | `Double` | Percentage saved |

### Errors

| Error | Description |
|-------|-------------|
| `invalidArgument` | Invalid argument provided |
| `ioError` | I/O error |
| `decodeFailed` | Input is not a valid PNG |
| `encodeFailed` | Encoding failed |
| `qualityTooLow` | Quality below minimum threshold |
| `outputLarger` | Output exceeds input size (with `skipIfLarger`) |

## Development

```bash
# Build XCFramework (local development)
bash scripts/build-xcframework.sh --local-only

# Build and test
swift build
swift test
```

## License

MIT - Copyright (c) 2026 okooo5km(十里)
