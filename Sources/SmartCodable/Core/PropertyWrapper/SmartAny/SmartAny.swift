//
//  SmartAny.swift
//  SmartCodable
//
//  Created by Mccc on 2024/6/13.
//

/**
 * A property wrapper that enables dynamic type handling for Codable properties.
 *
 * Usage Example:
 *
 * ```
 * struct UserProfile: SmartCodable {
 *     @SmartAny var name: Any?          // Can be String, Int, etc.
 *     @SmartAny var age: Any?           // Number or other types
 *     @SmartAny var metadata: [String: Any] = [:]  // Flexible dictionary
 *     @SmartAny var tags: [Any] = []    // Mixed-type array
 * }
 * ```
 */
@propertyWrapper
public struct SmartAny<T>: Codable, PropertyWrapperInitializable {
    
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    public static func createInstance(with value: Any) -> SmartAny<T>? {
        if let value = value as? T {
            return SmartAny(wrappedValue: value)
        }
        return nil
    }

    public init(from decoder: Decoder) throws {
        guard let decoder = decoder as? JSONDecoderImpl else {
            throw DecodingError.typeMismatch(SmartAnyImpl.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "Expected \(Self.self) value，but an exception occurred！Please report this issue（请上报该问题）")
            )
        }
        let value = decoder.json
        if let key = decoder.codingPath.last {
            // Note the case where T is nil. nil as? T is true.
            if let tranformer = decoder.cache.valueTransformer(for: key, codingPath: decoder.codingPath) {
                if let decoded = tranformer.tranform(value: value) as? T {
                    self = .init(wrappedValue: decoded)
                    return
                } else {
                    throw DecodingError.typeMismatch(Self.self, DecodingError.Context(
                        codingPath: decoder.codingPath, debugDescription: "Expected \(Self.self) value，but an exception occurred！"))
                }
            }
        }
                
        if let decoded = try? decoder.unwrap(as: SmartAnyImpl.self), let peel = decoded.peel as? T {
            self = .init(wrappedValue: peel)
        } else {
            
            // 类型检查
            if let _type = T.self as? Decodable.Type {
                if let decoded = try _type.init(from: decoder) as? T {
                    self = .init(wrappedValue: decoded)
                    return
                }
            }
            
            // Exceptions thrown in the parse container will be compatible.
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "Expected \(Self.self) value，but an exception occurred！")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        if let dict = wrappedValue as? [String: Any] {
            let value = dict.cover
            try container.encode(value)
        } else if let arr = wrappedValue as? [Any] {
            let value = arr.cover
            try container.encode(value)
        } else if let model = wrappedValue as? SmartCodable {
            try container.encode(model)
        } else {
            let value = SmartAnyImpl(from: wrappedValue)
            try container.encode(value)
        }
    }
}


extension SmartAny: PostDecodingHookable {
    func wrappedValueDidFinishMapping() -> SmartAny<T>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartAny(wrappedValue: temp as! T)
        }
        return nil
    }
}
