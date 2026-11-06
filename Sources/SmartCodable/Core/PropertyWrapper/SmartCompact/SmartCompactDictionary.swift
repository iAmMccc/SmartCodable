//
//  SmartLossyDictionary.swift
//  SmartCodable
//
//  Created by Mccc on 2026/1/22.
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
        // .recursive：整个数据容器交给统一动态桥（JSONEncoderImpl.wrapDynamicValue）整体编码，
        // 数据键保持原样，不再经过 smartKeyEncodingStrategy 的键转换，与 @SmartAny 行为一致。
        // 必须在创建 keyed container 之前分支，否则数据键会被键策略转换并可能相互覆盖。
        if let impl = encoder as? JSONEncoderImpl,
           impl.options.dynamicValueEncodingStrategy == .recursive {
            var data: [String: Any] = [:]
            for (k, v) in wrappedValue {
                guard v is Encodable || JSONValue.make(v) != nil else { continue }
                data[k.description] = v
            }
            impl.singleValue = try impl.wrapDynamicValue(data)
            return
        }

        var container = encoder.container(keyedBy: _JSONKey.self)
        for (k, v) in wrappedValue {
            // The legacy path accepts runtime Encodable values only. JSON-only
            // containers and null values require the explicit recursive bridge.
            guard v is Encodable else { continue }
            let key = _JSONKey(stringValue: k.description, intValue: nil)
            try container.encode(AnyEncodableBox(value: v), forKey: key)
        }
    }
}
