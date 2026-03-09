// Copyright (c) 2026 okooo5km(十里). All rights reserved.
// Licensed under the MIT License.

import Foundation

extension PNGOptim {

  /// Quality range for PNG quantization.
  public struct QualityRange: Sendable, Equatable {
    /// Minimum acceptable quality (0-100).
    public let min: UInt8
    /// Maximum (target) quality (0-100).
    public let max: UInt8

    /// Create a quality range from a closed range.
    ///
    /// - Parameter range: Quality range (e.g., `60...80`).
    public init(_ range: ClosedRange<UInt8>) {
      self.min = Swift.min(range.lowerBound, 100)
      self.max = Swift.min(range.upperBound, 100)
    }

    /// Create a quality range with explicit min and max values.
    ///
    /// - Parameters:
    ///   - min: Minimum acceptable quality (0-100).
    ///   - max: Maximum (target) quality (0-100).
    public init(min: UInt8, max: UInt8) {
      self.min = Swift.min(min, 100)
      self.max = Swift.min(max, 100)
    }
  }

  /// APNG handling mode.
  public enum APNGMode: UInt8, Sendable, Equatable {
    /// Safe mode: skip APNG files without error.
    case safe = 0
    /// Aggressive mode: quantize first frame, discard animation.
    case aggressive = 1
  }

  /// Options for PNG quantization.
  public struct Options: Sendable {
    /// Quality constraint. `nil` means no quality constraint (best effort).
    public var quality: QualityRange?

    /// Speed preset (1-11). Lower is slower but higher quality. Default is 4.
    public var speed: UInt8

    /// Dithering level (0.0-1.0). Default is 1.0 (full dithering).
    /// Set to 0.0 to disable dithering.
    public var ditherLevel: Float

    /// Posterize bits (0-8). Default is 0 (disabled).
    /// Reduces the number of distinct color levels per channel.
    public var posterize: UInt8

    /// Strip metadata (text chunks, ICC profile, etc.) from the output.
    public var strip: Bool

    /// Skip producing output if it would be larger than the input.
    public var skipIfLarger: Bool

    /// Skip ICC profile color-space normalization.
    public var noICC: Bool

    /// APNG handling mode. Default is `.safe`.
    public var apngMode: APNGMode

    /// Default options: no quality constraint, speed 4, full dithering.
    public static let `default` = Options()

    /// Create optimization options.
    ///
    /// - Parameters:
    ///   - quality: Quality constraint range (e.g., `QualityRange(60...80)`). Default is `nil` (no constraint).
    ///   - speed: Speed preset (1-11). Default is 4.
    ///   - ditherLevel: Dithering level (0.0-1.0). Default is 1.0.
    ///   - posterize: Posterize bits (0-8). Default is 0 (disabled).
    ///   - strip: Strip metadata. Default is `false`.
    ///   - skipIfLarger: Skip if output is larger. Default is `false`.
    ///   - noICC: Skip ICC normalization. Default is `false`.
    ///   - apngMode: APNG handling mode. Default is `.safe`.
    public init(
      quality: QualityRange? = nil,
      speed: UInt8 = 4,
      ditherLevel: Float = 1.0,
      posterize: UInt8 = 0,
      strip: Bool = false,
      skipIfLarger: Bool = false,
      noICC: Bool = false,
      apngMode: APNGMode = .safe
    ) {
      self.quality = quality
      self.speed = speed
      self.ditherLevel = ditherLevel
      self.posterize = posterize
      self.strip = strip
      self.skipIfLarger = skipIfLarger
      self.noICC = noICC
      self.apngMode = apngMode
    }
  }
}
