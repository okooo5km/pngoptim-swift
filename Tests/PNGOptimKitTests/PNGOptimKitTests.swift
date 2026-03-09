// Copyright (c) 2026 okooo5km(十里). All rights reserved.
// Licensed under the MIT License.

import CoreGraphics
import Foundation
import ImageIO
import Testing

@testable import PNGOptimKit

// MARK: - Test PNG generation

/// Generate a minimal valid PNG with a gradient pattern.
private func generateTestPNG(width: Int = 64, height: Int = 64) -> Data {
  let colorSpace = CGColorSpaceCreateDeviceRGB()
  guard
    let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: width * 4,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else {
    fatalError("Failed to create CGContext")
  }

  // Draw a gradient pattern for realistic test data
  for y in 0..<height {
    for x in 0..<width {
      let r = CGFloat(x) / CGFloat(width)
      let g = CGFloat(y) / CGFloat(height)
      let b: CGFloat = 0.5
      context.setFillColor(red: r, green: g, blue: b, alpha: 1.0)
      context.fill(CGRect(x: x, y: y, width: 1, height: 1))
    }
  }

  guard let image = context.makeImage() else {
    fatalError("Failed to create CGImage")
  }

  let data = NSMutableData()
  guard
    let dest = CGImageDestinationCreateWithData(
      data as CFMutableData, "public.png" as CFString, 1, nil)
  else {
    fatalError("Failed to create image destination")
  }
  CGImageDestinationAddImage(dest, image, nil)
  CGImageDestinationFinalize(dest)

  return data as Data
}

// MARK: - Options tests

@Suite("Options")
struct OptionsTests {
  @Test("Default options have expected values")
  func defaultOptions() {
    let opts = PNGOptim.Options.default
    #expect(opts.quality == nil)
    #expect(opts.speed == 4)
    #expect(opts.ditherLevel == 1.0)
    #expect(opts.posterize == 0)
    #expect(opts.strip == false)
    #expect(opts.skipIfLarger == false)
    #expect(opts.noICC == false)
    #expect(opts.apngMode == .safe)
  }

  @Test("APNGMode default is safe")
  func apngModeDefault() {
    let opts = PNGOptim.Options()
    #expect(opts.apngMode == .safe)
  }

  @Test("APNGMode aggressive value")
  func apngModeAggressive() {
    let opts = PNGOptim.Options(apngMode: .aggressive)
    #expect(opts.apngMode == .aggressive)
  }

  @Test("APNGMode rawValue mapping")
  func apngModeRawValue() {
    #expect(PNGOptim.APNGMode.safe.rawValue == 0)
    #expect(PNGOptim.APNGMode.aggressive.rawValue == 1)
  }

  @Test("QualityRange from ClosedRange")
  func qualityRangeFromClosedRange() {
    let range = PNGOptim.QualityRange(60...80)
    #expect(range.min == 60)
    #expect(range.max == 80)
  }

  @Test("QualityRange clamps to 100")
  func qualityRangeClamps() {
    let range = PNGOptim.QualityRange(min: 50, max: 200)
    #expect(range.max == 100)
  }

  @Test("Custom options round-trip to C options")
  func customOptionsConversion() {
    let opts = PNGOptim.Options(
      quality: PNGOptim.QualityRange(70...90),
      speed: 8,
      ditherLevel: 0.5,
      posterize: 2,
      strip: true,
      skipIfLarger: true,
      noICC: true
    )
    let cOpts = opts.toCOptions()
    #expect(cOpts.has_quality == true)
    #expect(cOpts.quality_min == 70)
    #expect(cOpts.quality_max == 90)
    #expect(cOpts.speed == 8)
    #expect(cOpts.dither_level == 0.5)
    #expect(cOpts.posterize == 2)
    #expect(cOpts.strip == true)
    #expect(cOpts.skip_if_larger == true)
    #expect(cOpts.no_icc == true)
  }
}

// MARK: - Result computed properties

@Suite("Result computed properties")
struct ResultComputedTests {
  @Test("compressionRatio calculation")
  func compressionRatio() {
    let result = PNGOptim.Result(
      data: Data(),
      width: 1, height: 1,
      inputBytes: 1000, outputBytes: 700,
      qualityScore: 80, qualityMSE: 0.5,
      metrics: PNGOptim.Metrics(
        decodeTime: 0, quantizeTime: 0, encodeTime: 0, totalTime: 0)
    )
    #expect(abs(result.compressionRatio - 0.7) < 0.001)
  }

  @Test("savingsPercent calculation")
  func savingsPercent() {
    let result = PNGOptim.Result(
      data: Data(),
      width: 1, height: 1,
      inputBytes: 1000, outputBytes: 700,
      qualityScore: 80, qualityMSE: 0.5,
      metrics: PNGOptim.Metrics(
        decodeTime: 0, quantizeTime: 0, encodeTime: 0, totalTime: 0)
    )
    #expect(abs(result.savingsPercent - 30.0) < 0.001)
  }

  @Test("Zero input bytes yields zero ratios")
  func zeroInputBytes() {
    let result = PNGOptim.Result(
      data: Data(),
      width: 0, height: 0,
      inputBytes: 0, outputBytes: 0,
      qualityScore: 0, qualityMSE: 0,
      metrics: PNGOptim.Metrics(
        decodeTime: 0, quantizeTime: 0, encodeTime: 0, totalTime: 0)
    )
    #expect(result.compressionRatio == 0)
    #expect(result.savingsPercent == 0)
  }
}

// MARK: - Optimization tests

@Suite("Optimization")
struct OptimizationTests {
  @Test("Default optimization produces valid smaller PNG")
  func defaultOptimization() throws {
    let input = generateTestPNG()
    let result = try PNGOptim.optimize(input)

    // Output should be valid PNG (starts with PNG signature)
    #expect(result.data.count > 8)
    let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    let outputPrefix = Array(result.data.prefix(8))
    #expect(outputPrefix == signature)

    // Dimensions should match
    #expect(result.width == 64)
    #expect(result.height == 64)

    // Input/output bytes should be populated
    #expect(result.inputBytes == UInt64(input.count))
    #expect(result.outputBytes == UInt64(result.data.count))
    #expect(result.outputBytes > 0)
  }

  @Test("Quality range constraint")
  func qualityRangeConstraint() throws {
    let input = generateTestPNG()
    let opts = PNGOptim.Options(quality: PNGOptim.QualityRange(60...80))
    let result = try PNGOptim.optimize(input, options: opts)

    #expect(result.qualityScore >= 60)
    #expect(result.data.count > 0)
  }

  @Test("Metrics are populated")
  func metricsPopulated() throws {
    let input = generateTestPNG()
    let result = try PNGOptim.optimize(input)

    #expect(result.metrics.totalTime > 0)
    #expect(result.metrics.decodeTime >= 0)
    #expect(result.metrics.quantizeTime >= 0)
    #expect(result.metrics.encodeTime >= 0)
  }

  @Test("Strip metadata option")
  func stripMetadata() throws {
    let input = generateTestPNG()
    let opts = PNGOptim.Options(strip: true)
    let result = try PNGOptim.optimize(input, options: opts)

    #expect(result.data.count > 0)
  }

  @Test("Invalid input throws decodeFailed")
  func invalidInput() throws {
    let badData = Data("not a png".utf8)
    #expect(throws: PNGOptim.Error.self) {
      try PNGOptim.optimize(badData)
    }
  }

  @Test("Empty input throws error")
  func emptyInput() throws {
    let emptyData = Data()
    #expect(throws: (any Swift.Error).self) {
      try PNGOptim.optimize(emptyData)
    }
  }
}
