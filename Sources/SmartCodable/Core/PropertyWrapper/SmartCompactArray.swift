//
//  SmartCompact.swift
//  SmartCodable
//
//  Created by Mccc on 2026/1/21.
//

@propertyWrapper
public struct SmartCompact<T>: PropertyWrapperable {
    
    public var wrappedValue: [T]
    
    public init(wrappedValue: [T]) {
        self.wrappedValue = wrappedValue
    }
    
    public func wrappedValueDidFinishMapping() -> SmartCompact? {
        guard var temp = wrappedValue as? SmartDecodable else { return nil }
        temp.didFinishMapping()
        return SmartCompact(wrappedValue: temp as! [T])
    }
    
    /// Creates an instance from any value if possible
    public static func createInstance(with value: Any) -> SmartCompact? {
        guard let value = value as? [T] else { return nil }
        return SmartCompact(wrappedValue: value)
    }
}

extension SmartCompact: Codable {
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


private struct DummyDecodable: Decodable { }
