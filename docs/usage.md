# PNGOptimKit Usage Guide

## Installation

Add PNGOptimKit to your Swift package:

```swift
// Package.swift
dependencies: [
  .package(url: "https://github.com/okooo5km/pngoptim-swift.git", from: "0.4.1")
],
targets: [
  .target(
    name: "YourApp",
    dependencies: ["PNGOptimKit"]
  )
]
```

## Quick Start

```swift
import PNGOptimKit

let data = try Data(contentsOf: URL(fileURLWithPath: "input.png"))
let result = try PNGOptim.optimize(data)
try result.data.write(to: URL(fileURLWithPath: "output.png"))
```

## API Reference

### PNGOptim.optimize(_:options:)

The main entry point for PNG optimization.

```swift
public static func optimize(_ data: Data, options: Options = .default) throws -> Result
```

- **`data`**: Raw PNG file bytes. Both static PNG and APNG are accepted.
- **`options`**: Compression options. Defaults to `Options.default`.
- **Returns**: A `Result` containing the optimized PNG data and metadata.
- **Throws**: `PNGOptim.Error` on failure.

### Options

Configure optimization behavior via `PNGOptim.Options`.

```swift
public struct Options: Sendable {
  var quality: QualityRange?   // nil = no constraint (best effort)
  var speed: UInt8             // 1-11, default 4
  var ditherLevel: Float       // 0.0-1.0, default 1.0
  var posterize: UInt8         // 0-8, default 0 (disabled)
  var strip: Bool              // default false
  var skipIfLarger: Bool       // default false
  var noICC: Bool              // default false
  var apngMode: APNGMode       // default .safe
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `quality` | `QualityRange?` | `nil` | Quality constraint. `nil` means best effort with no minimum. |
| `speed` | `UInt8` | `4` | Speed preset. 1 = slowest/best quality, 11 = fastest. |
| `ditherLevel` | `Float` | `1.0` | Dithering intensity. 0.0 disables dithering. |
| `posterize` | `UInt8` | `0` | Reduce distinct color levels per channel. 0 = disabled. |
| `strip` | `Bool` | `false` | Remove metadata (text chunks, ICC profile, etc.). |
| `skipIfLarger` | `Bool` | `false` | Throw `outputLarger` if the result is bigger than the input. |
| `noICC` | `Bool` | `false` | Skip ICC profile color-space normalization. |
| `apngMode` | `APNGMode` | `.safe` | APNG handling strategy. See [APNGMode](#apngmode). |

### QualityRange

Constrains the acceptable quality of the output.

```swift
// From a closed range
let q1 = PNGOptim.QualityRange(60...80)

// From explicit min/max
let q2 = PNGOptim.QualityRange(min: 60, max: 80)
```

Values are clamped to 0–100. If the achieved quality falls below `min`, the engine throws `qualityTooLow`.

### APNGMode

Controls how animated PNG files are processed.

```swift
public enum APNGMode: UInt8, Sendable, Equatable {
  case safe = 0
  case aggressive = 1
}
```

| Mode | Behavior |
|------|----------|
| `.safe` | Fold duplicate frames and cautious transparent trim. Conservative approach with minimal structural changes. |
| `.aggressive` | Minimize frame rectangles by rewriting frame sizes, offsets, and blend operations for higher compression. |

Both modes perform **lossless** APNG optimization (quality score = 100) — animation frames are never discarded or quantized.

### Result

Returned by `optimize(_:options:)` on success.

```swift
public struct Result: Sendable {
  let data: Data            // Optimized PNG bytes
  let width: UInt32         // Image width in pixels
  let height: UInt32        // Image height in pixels
  let inputBytes: UInt64    // Original file size
  let outputBytes: UInt64   // Optimized file size
  let qualityScore: UInt8   // Achieved quality (0-100)
  let qualityMSE: Double    // Mean squared error
  let metrics: Metrics      // Timing breakdown

  // Computed
  var compressionRatio: Double  // outputBytes / inputBytes
  var savingsPercent: Double    // Percentage saved (0-100)
}
```

### Metrics

Performance timing for each processing phase.

```swift
public struct Metrics: Sendable {
  let decodeTime: TimeInterval    // PNG decoding (seconds)
  let quantizeTime: TimeInterval  // Color quantization (seconds)
  let encodeTime: TimeInterval    // PNG encoding (seconds)
  let totalTime: TimeInterval     // Total processing (seconds)
}
```

### Error

All errors conform to `LocalizedError`.

```swift
public enum Error: LocalizedError, Sendable {
  case invalidArgument(String)
  case ioError(String)
  case decodeFailed(String)
  case encodeFailed(String)
  case qualityTooLow(minimum: UInt8, actual: UInt8)
  case outputLarger(inputBytes: UInt64, outputBytes: UInt64,
                    maximumFileSize: UInt64, qualityScore: UInt8)
  case unknown(code: Int32, message: String)
}
```

**FFI error code mapping:**

| Code | Swift Error |
|------|-------------|
| 0 | (success) |
| 1 | `invalidArgument` |
| 2 | `ioError` |
| 3 | `decodeFailed` |
| 4 | `encodeFailed` |
| 98 | `qualityTooLow` |
| 99 | `outputLarger` |

## Usage Examples

### Basic Compression

```swift
import PNGOptimKit

let input = try Data(contentsOf: imageURL)
let result = try PNGOptim.optimize(input)
print("Compressed: \(result.inputBytes) → \(result.outputBytes) bytes")
print("Saved \(String(format: "%.1f", result.savingsPercent))%")
```

### Custom Quality and Speed

```swift
let options = PNGOptim.Options(
  quality: PNGOptim.QualityRange(70...90),
  speed: 2,           // Slower, higher quality
  ditherLevel: 0.8,
  strip: true
)
let result = try PNGOptim.optimize(input, options: options)
```

### APNG Processing

```swift
// Safe mode (default) — conservative optimization
let safeResult = try PNGOptim.optimize(apngData)

// Aggressive mode — maximize compression
let aggressiveOptions = PNGOptim.Options(apngMode: .aggressive)
let aggressiveResult = try PNGOptim.optimize(apngData, options: aggressiveOptions)
```

For APNG files, `qualityScore` is always 100 (lossless optimization).

### Error Handling

```swift
do {
  let result = try PNGOptim.optimize(data, options: options)
  try result.data.write(to: outputURL)
} catch let error as PNGOptim.Error {
  switch error {
  case .qualityTooLow(let minimum, let actual):
    print("Quality \(actual) below minimum \(minimum), try lowering quality range")
  case .outputLarger(let input, let output, _, _):
    print("Output \(output) bytes > input \(input) bytes, skipped")
  case .decodeFailed(let msg):
    print("Not a valid PNG: \(msg)")
  default:
    print(error.localizedDescription)
  }
}
```

## APNG Deep Dive

### Automatic Detection

PNGOptimKit detects APNG files by checking for the `acTL` (Animation Control) chunk in the PNG data stream. No manual configuration is needed — the engine automatically switches to the APNG pipeline when animation is detected.

### Safe vs Aggressive

| Aspect | Safe (`.safe`) | Aggressive (`.aggressive`) |
|--------|---------------|---------------------------|
| Duplicate frames | Folded (merged) | Folded (merged) |
| Transparent trim | Cautious edge trimming | Full rectangle minimization |
| Frame metadata | Preserved | Rewritten (size, offset, blend ops) |
| Compression | Moderate | Higher |
| Risk | Minimal | Low (still lossless) |

### Lossless Processing

Both APNG modes are **lossless** — the output is visually identical to the input. The optimization focuses on structural redundancy:
- Merging identical consecutive frames
- Trimming transparent regions around frame content
- Minimizing frame rectangle dimensions

The `qualityScore` for APNG output is always `100`.

### Fallback Behavior

If the APNG decoder encounters an error (e.g., malformed animation chunks), the engine falls back to the standard static PNG quantization pipeline. In this case, only the default image (first frame) is processed with lossy quantization, and `qualityScore` reflects the quantization quality.

## Troubleshooting

### `qualityTooLow`

Thrown when the achieved quality is below the `quality.min` threshold. Solutions:
- Lower the minimum quality (e.g., `QualityRange(40...80)` instead of `QualityRange(70...80)`)
- Increase `speed` for less aggressive quantization
- Remove the quality constraint (`quality: nil`)

### `outputLarger`

Thrown when `skipIfLarger` is enabled and the optimized output exceeds the input size. This typically happens with:
- Already-optimized PNG files
- Very small images where metadata overhead dominates
- Images with few colors that don't benefit from quantization

### Verifying APNG Detection

To confirm a file was processed as APNG, check the `qualityScore` — APNG optimization always returns `100`. Static PNG quantization typically returns a lower score.
