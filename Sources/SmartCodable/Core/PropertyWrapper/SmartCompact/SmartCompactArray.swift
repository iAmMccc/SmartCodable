//
//  SmartCompact.swift
//  SmartCodable
//
//  Created by Mccc on 2026/1/21.
//



private struct DummyDecodable: Decodable { }

extension SmartCompact {
    @propertyWrapper
    public struct Array<T> {
        
        public var wrappedValue: [T]
        
        public init(wrappedValue: [T]) {
            self.wrappedValue = wrappedValue
        }
    }
}

extension SmartCompact.Array: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [T] = []
        
        
        // 1. 生成 decode 闭包
        let decodeValue: () -> Any? = {
            if T.self is SmartCodableX.Type,
               let type = T.self as? Decodable.Type {
                return try? container.decode(type)
            } else {
                return try? container.decode(SmartAnyImpl.self).peel
            }
        }

        // 2. 统一循环
        while !container.isAtEnd {
            let startIndex = container.currentIndex
            defer {
                // 如果 decode 失败，确保 index 被推进
                if container.currentIndex == startIndex {
                    _ = try? container.decode(DummyDecodable.self)
                }
            }

            // decode
            if let value = decodeValue(), let v = value as? T {
                result.append(v)
            }
        }

        self.wrappedValue = result
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for value in wrappedValue {
            try container.encode(SmartAnyImpl(from: value))
        }
    }
}
