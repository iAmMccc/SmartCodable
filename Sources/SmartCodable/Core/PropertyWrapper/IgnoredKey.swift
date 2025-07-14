//
//  Ignored.swift
//  SmartCodable
//
//  Created by Mccc on 2024/4/30.
//

import Foundation

/**
 A property wrapper that marks a property to be ignored during encoding/decoding.
 
 Key Usage Notes:
 1. Doesn't truly ignore parsing of the decorated property, but ignores using the parsed data.
 2. Different handling based on data presence:
    - When data exists: Enters `encode(to:)` method and throws an exception for external handling
    - When no data exists: Treated as normal data parsing, falls back to default logic
 
 - Note: This is particularly useful for properties that should maintain their default values
   rather than being overwritten by decoded values.
 */
@propertyWrapper
public struct IgnoredKey<T>: Codable {
    
    /// The underlying value being wrapped
    public var wrappedValue: T

    /// Determines whether this property should be included in encoding
    var isEncodable: Bool = true
    

    /// Initializes an IgnoredKey with a wrapped value and encoding control
    /// - Parameters:
    ///   - wrappedValue: The initial/default value
    ///   - isEncodable: Whether the property should be included in encoding (default: false)
    public init(wrappedValue: T, isEncodable: Bool = false) {
        self.wrappedValue = wrappedValue
        self.isEncodable = isEncodable
    }

    public init(from decoder: Decoder) throws {
        // Attempt to get default value first
        guard let impl = decoder as? JSONDecoderImpl else {
            wrappedValue = try Patcher<T>.defaultForType()
            return
        }
        
        // Support for custom decoding strategies on IgnoredKey properties
        if let key = impl.codingPath.last {
            if let tranformer = impl.cache.valueTransformer(for: key, codingPath: impl.codingPath) {
                if let decoded = tranformer.tranform(value: impl.json) as? T {
                    wrappedValue = decoded
                    return
                }
            }
        }
        
        /// Special handling for SmartJSONDecoder parser - throws exceptions to be handled by container
        if let key = CodingUserInfoKey.parsingMark, let _ = impl.userInfo[key] {
            throw DecodingError.typeMismatch(IgnoredKey<T>.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "\(Self.self) does not participate in the parsing, please ignore it.")
            )
        }
        
        /// The resolution triggered by the other three parties may be resolved here.
        wrappedValue = try impl.smartDecode(type: T.self)
    }

    public func encode(to encoder: Encoder) throws {
        
        guard isEncodable else { return }
        
        if let impl = encoder as? JSONEncoderImpl,
            let key = impl.codingPath.last,
           let jsonValue = impl.cache.tranform(from: wrappedValue, with: key, codingPath: impl.codingPath),
            let value = jsonValue.peel as? Encodable {
            try value.encode(to: encoder)
            return
        }
        
        // Manual encoding for Encodable types, nil otherwise
        if let encodableValue = wrappedValue as? Encodable {
            try encodableValue.encode(to: encoder)
        } else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}
extension JSONDecoderImpl {
    fileprivate func smartDecode<T>(type: T.Type) throws -> T {
        try cache.initialValue(forKey: codingPath.last, codingPath: codingPath)
    }
}
