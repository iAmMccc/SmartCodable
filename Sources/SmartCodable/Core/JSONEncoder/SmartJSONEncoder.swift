

import Foundation

//===----------------------------------------------------------------------===//
// JSON Encoder
//===----------------------------------------------------------------------===//

/// `JSONEncoder` facilitates the encoding of `Encodable` values into JSON.
open class SmartJSONEncoder: JSONEncoder, @unchecked Sendable {

    open var smartKeyEncodingStrategy: SmartKeyEncodingStrategy = .useDefaultKeys
    open var smartDataEncodingStrategy: SmartDataEncodingStrategy = .base64

   
    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    struct _Options {
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: SmartDataEncodingStrategy
        let nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy
        let keyEncodingStrategy: SmartKeyEncodingStrategy
        let userInfo: [CodingUserInfoKey: Any]
    }

    /// The options set on the top-level encoder.
    fileprivate var options: _Options {
        return _Options(dateEncodingStrategy: .secondsSince1970,
                        dataEncodingStrategy: smartDataEncodingStrategy,
                        nonConformingFloatEncodingStrategy: nonConformingFloatEncodingStrategy,
                        keyEncodingStrategy: smartKeyEncodingStrategy,
                        userInfo: userInfo)
    }


    // MARK: - Encoding Values

    /// Encodes the given top-level value and returns its JSON representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded JSON data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open override func encode<T: Encodable>(_ value: T) throws -> Data {
        let jsonValue: JSONValue = try encodeAsJSONValue(value)
        let jsonObject = jsonValue.toFoundation()
        
        do {
            return try JSONSerialization.data(withJSONObject: jsonObject, options: self.outputFormatting.jsonSerializationOptions)
        } catch {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unable to encode the given top-level value to JSON.", underlyingError: error))
        }
    }
    
    func mapOutputFormatting(_ formatting: JSONEncoder.OutputFormatting) -> JSONSerialization.WritingOptions {
        var options = JSONSerialization.WritingOptions()
        
        if formatting.contains(.prettyPrinted) {
            options.insert(.prettyPrinted)
        }
        if formatting.contains(.sortedKeys) {
            if #available(iOS 11.0, macOS 10.13, *) {
                options.insert(.sortedKeys)
            }
        }
        
        return options
    }

    func encodeAsJSONValue<T: Encodable>(_ value: T) throws -> JSONValue {
        let encoder = JSONEncoderImpl(options: self.options, codingPath: [])
        guard let topLevel = try encoder.wrapEncodable(value, for: nil) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
        }

        return topLevel
    }
}

//===----------------------------------------------------------------------===//
// Error Utilities
//===----------------------------------------------------------------------===//

extension EncodingError {
    /// Returns a `.invalidValue` error describing the given invalid floating-point value.
    ///
    ///
    /// - parameter value: The value that was invalid to encode.
    /// - parameter path: The path of `CodingKey`s taken to encode this value.
    /// - returns: An `EncodingError` with the appropriate path and debug description.
    fileprivate static func _invalidFloatingPointValue<T: FloatingPoint>(_ value: T, at codingPath: [CodingKey]) -> EncodingError {
        let valueDescription: String
        if value == T.infinity {
            valueDescription = "\(T.self).infinity"
        } else if value == -T.infinity {
            valueDescription = "-\(T.self).infinity"
        } else {
            valueDescription = "\(T.self).nan"
        }

        let debugDescription = "Unable to encode \(valueDescription) directly in JSON. Use SmartJSONEncoder.NonConformingFloatEncodingStrategy.convertToString to specify how the value should be encoded."
        return .invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: debugDescription))
    }
}

extension CodingUserInfoKey {
    /// 是否使用映射之后的key
    static let useMappedKeys = CodingUserInfoKey.init(rawValue: "Stamrt.useMappedKeys")
}

extension JSONEncoder.OutputFormatting {
    var jsonSerializationOptions: JSONSerialization.WritingOptions {
        var options: JSONSerialization.WritingOptions = []
        if contains(.prettyPrinted) {
            options.insert(.prettyPrinted)
        }
        if self.contains(.sortedKeys) {
            if #available(iOS 11.0, macOS 10.13, *) {
                options.insert(.sortedKeys)
            }
        }
        return options
    }
}
