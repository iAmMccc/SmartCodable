//
//  SmartIgnored.swift
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
public struct SmartIgnored<T>: PropertyWrapperable {
    
    /// The underlying value being wrapped
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    public func wrappedValueDidFinishMapping() -> SmartIgnored<T>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartIgnored(wrappedValue: temp as! T, isEncodable: isEncodable)
        }
        return nil
    }
        
    /// Creates an instance from any value if possible
    public static func createInstance(with value: Any) -> SmartIgnored? {
        if let value = value as? T {
            return SmartIgnored(wrappedValue: value)
        }
        return nil
    }
    
    
    
    /// Determines whether this property should be included in encoding
    var isEncodable: Bool = false
    
    /// Initializes an SmartIgnored with a wrapped value and encoding control
    /// - Parameters:
    ///   - wrappedValue: The initial/default value
    ///   - isEncodable: Whether the property should be included in encoding (default: false)
    public init(wrappedValue: T, isEncodable: Bool = false) {
        self.wrappedValue = wrappedValue
        self.isEncodable = isEncodable
    }
}


extension SmartIgnored: Codable {
    public init(from decoder: Decoder) throws {
        // Attempt to get default value first
        guard let impl = decoder as? JSONDecoderImpl else {
            wrappedValue = try Patcher<T>.defaultForType()
            return
        }

        /// Special handling for SmartJSONDecoder parser - throws exceptions to be handled by container
        if let key = CodingUserInfoKey.parsingMark, let _ = impl.userInfo[key] {
            throw DecodingError.typeMismatch(SmartIgnored<T>.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "\(Self.self) does not participate in the parsing, please ignore it.")
            )
        }
        
        // 第三方解码路径（无 parsingMark）下，经当前属性边从宿主上下文恢复完整的包装器声明，
        // 确保包装器自身的配置状态（如 isEncodable）及 wrappedValue 完整保留。
        // 根级 wrapper 没有宿主声明可读时，沿用 Patcher 兜底。
        if let declared: Self = impl.propertyContext?.declaredWrapper(as: Self.self) {
            self = declared
        } else {
            wrappedValue = try Patcher<T>.defaultForType()
        }
    }

    public func encode(to encoder: Encoder) throws {
        
        guard isEncodable else { return }
        
        // Manual encoding for Encodable types, nil otherwise
        if let encodableValue = wrappedValue as? Encodable {
            try encodableValue.encode(to: encoder)
        } else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}
