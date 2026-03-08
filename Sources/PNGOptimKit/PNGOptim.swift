// Copyright (c) 2026 okooo5km(十里). All rights reserved.
// Licensed under the MIT License.

import CPNGOptim
import Foundation

/// PNG quantization (lossy compression) engine powered by pngoptim.
public enum PNGOptim {

  /// Optimize a PNG image with the given options.
  ///
  /// - Parameters:
  ///   - data: Raw PNG file data.
  ///   - options: Compression options (quality, speed, etc.).
  /// - Returns: Optimization result containing the compressed PNG data.
  /// - Throws: ``PNGOptim/Error`` if processing fails.
  public static func optimize(_ data: Data, options: Options = .default) throws -> Result {
    var cOptions = options.toCOptions()

    let resultPtr: UnsafeMutablePointer<PNGOptimResult>? = data.withUnsafeBytes {
      (buffer: UnsafeRawBufferPointer) -> UnsafeMutablePointer<PNGOptimResult>? in
      guard let baseAddress = buffer.baseAddress else {
        return nil
      }
      let inputPtr = baseAddress.assumingMemoryBound(to: UInt8.self)
      return CPNGOptim.pngoptim_process(inputPtr, UInt(buffer.count), &cOptions)
    }

    guard let ptr = resultPtr else {
      throw Error.invalidArgument("Input data is empty or null")
    }
    defer { pngoptim_result_free(ptr) }

    let result = ptr.pointee

    // Check for errors
    if result.error_code != 0 {
      throw Error.fromCResult(result)
    }

    // Copy output data
    guard result.data != nil, result.data_len > 0 else {
      throw Error.encodeFailed("No output data produced")
    }

    let outputData = Data(bytes: result.data, count: Int(result.data_len))

    return Result(
      data: outputData,
      width: result.width,
      height: result.height,
      inputBytes: result.input_bytes,
      outputBytes: result.output_bytes,
      qualityScore: result.quality_score,
      qualityMSE: result.quality_mse,
      metrics: Metrics(
        decodeTime: TimeInterval(result.decode_ms / 1000.0),
        quantizeTime: TimeInterval(result.quantize_ms / 1000.0),
        encodeTime: TimeInterval(result.encode_ms / 1000.0),
        totalTime: TimeInterval(result.total_ms / 1000.0)
      )
    )
  }
}

// MARK: - Private helpers

extension PNGOptim.Options {
  func toCOptions() -> PNGOptimOptions {
    var opts = pngoptim_default_options()
    if let q = quality {
      opts.has_quality = true
      opts.quality_min = q.min
      opts.quality_max = q.max
    } else {
      opts.has_quality = false
    }
    opts.speed = speed
    opts.dither_level = ditherLevel
    opts.posterize = posterize
    opts.strip = strip
    opts.skip_if_larger = skipIfLarger
    opts.no_icc = noICC
    return opts
  }
}

