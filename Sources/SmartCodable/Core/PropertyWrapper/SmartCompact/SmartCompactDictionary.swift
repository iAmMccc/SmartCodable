//
//  SmartLossyDictionary.swift
//  SmartCodable
//
//  Created by qixin on 2026/1/22.
//

import Foundation


extension SmartCompact {
    @propertyWrapper
    public struct Dictionary<Key: Hashable & LosslessStringConvertible, Value> {
        
        public var wrappedValue: [Key: Value]
        
        public init(wrappedValue: [Key: Value]) {
            self.wrappedValue = wrappedValue
        }
    }
}


extension SmartCompact.Dictionary: Codable {
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: _JSONKey.self)
        var result: [Key: Value] = [:]
        
        
        for key in container.allKeys {
            
            guard let typedKey = Key(key.stringValue) else { continue }
            
            // 1. Value 不是 Any 类型，直接进行解析，
            if let _type = Value.self as? Decodable.Type {
                // 如果有值，就使用。如果没值就忽略该key-value
                if let decodedValue = try? container.decodeIfPresent(_type, forKey: key) as? Value {
                    result[typedKey] = decodedValue
                }
            }
            // 2. Value 是 Any 类型。 统一使用 JSONDecoderImpl 解析
            else if let decoderImpl = try? container.superDecoder(forKey: key) as? JSONDecoderImpl {
                // 2.1 先尝试 unwrap SmartAnyImpl
                if let decoded = try? decoderImpl.unwrap(as: SmartAnyImpl.self),
                   let peeled = decoded.peel as? Value {
                    result[typedKey] = peeled
                    continue
                }
                
                // 2.2 再尝试 Value 本身的 Decodable 解码（包含 SmartCodableX）
                if let _type = Value.self as? Decodable.Type,
                   let decoded = try? _type.init(from: decoderImpl) as? Value {
                    result[typedKey] = decoded
                    continue
                }
            }
        }
        
        self.wrappedValue = result
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: _JSONKey.self)
        for (k, v) in wrappedValue {
            if let key = _JSONKey(stringValue: k.description),
               let _v = v as? Encodable {
                try container.encode(_v, forKey: key)
            }
        }
    }
}
