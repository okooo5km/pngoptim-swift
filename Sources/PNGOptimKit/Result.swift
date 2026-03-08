// Copyright (c) 2026 okooo5km(十里). All rights reserved.
// Licensed under the MIT License.

import Foundation

extension PNGOptim {

  /// Performance timing metrics for a PNG optimization operation.
  public struct Metrics: Sendable {
    /// Time spent decoding the input PNG (seconds).
    public let decodeTime: TimeInterval
    /// Time spent quantizing the image (seconds).
    public let quantizeTime: TimeInterval
    /// Time spent encoding the output PNG (seconds).
    public let encodeTime: TimeInterval
    /// Total processing time (seconds).
    public let totalTime: TimeInterval
  }

  /// Result of a PNG optimization operation.
  public struct Result: Sendable {
    /// The optimized PNG data.
    public let data: Data
    /// Image width in pixels.
    public let width: UInt32
    /// Image height in pixels.
    public let height: UInt32
    /// Original input size in bytes.
    public let inputBytes: UInt64
    /// Optimized output size in bytes.
    public let outputBytes: UInt64
    /// Quality score (0-100).
    public let qualityScore: UInt8
    /// Quality MSE (mean squared error).
    public let qualityMSE: Double
    /// Performance timing metrics.
    public let metrics: Metrics

    /// Compression ratio (output / input). Values < 1.0 indicate size reduction.
    public var compressionRatio: Double {
      guard inputBytes > 0 else { return 0 }
      return Double(outputBytes) / Double(inputBytes)
    }

    /// Percentage of bytes saved (0-100). Higher is better.
    public var savingsPercent: Double {
      guard inputBytes > 0 else { return 0 }
      return (1.0 - Double(outputBytes) / Double(inputBytes)) * 100.0
    }
  }
}
