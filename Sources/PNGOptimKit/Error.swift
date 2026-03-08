// Copyright (c) 2026 okooo5km(十里). All rights reserved.
// Licensed under the MIT License.

import CPNGOptim
import Foundation

extension PNGOptim {

  /// Errors that can occur during PNG optimization.
  public enum Error: LocalizedError, Sendable {
    /// Invalid argument was provided.
    case invalidArgument(String)
    /// I/O error occurred.
    case ioError(String)
    /// Failed to decode the input PNG.
    case decodeFailed(String)
    /// Failed to encode the output PNG.
    case encodeFailed(String)
    /// The achieved quality is below the minimum specified in the quality range.
    case qualityTooLow(minimum: UInt8, actual: UInt8)
    /// The output file would be larger than the input (when `skipIfLarger` is enabled).
    case outputLarger(
      inputBytes: UInt64, outputBytes: UInt64, maximumFileSize: UInt64,
      qualityScore: UInt8)
    /// An unknown error occurred.
    case unknown(code: Int32, message: String)

    public var errorDescription: String? {
      switch self {
      case .invalidArgument(let msg):
        return "Invalid argument: \(msg)"
      case .ioError(let msg):
        return "I/O error: \(msg)"
      case .decodeFailed(let msg):
        return "PNG decode failed: \(msg)"
      case .encodeFailed(let msg):
        return "PNG encode failed: \(msg)"
      case .qualityTooLow(let minimum, let actual):
        return
          "Quality too low: achieved \(actual), minimum required \(minimum)"
      case .outputLarger(let input, let output, let maxSize, let quality):
        return
          "Output (\(output) bytes) exceeds maximum (\(maxSize) bytes) for input (\(input) bytes) at quality \(quality)"
      case .unknown(let code, let msg):
        return "Unknown error (code \(code)): \(msg)"
      }
    }

    /// Create an error from a C FFI result.
    static func fromCResult(_ result: PNGOptimResult) -> Error {
      let message: String
      if let msgPtr = result.error_message {
        message = String(cString: msgPtr)
      } else {
        message = "Unknown error"
      }

      switch result.error_code {
      case 1:
        return .invalidArgument(message)
      case 2:
        return .ioError(message)
      case 3:
        return .decodeFailed(message)
      case 4:
        return .encodeFailed(message)
      case 98:
        return .qualityTooLow(
          minimum: result.quality_minimum,
          actual: result.quality_score)
      case 99:
        return .outputLarger(
          inputBytes: result.input_bytes,
          outputBytes: result.output_bytes,
          maximumFileSize: result.maximum_file_size,
          qualityScore: result.quality_score)
      default:
        return .unknown(code: result.error_code, message: message)
      }
    }
  }
}
