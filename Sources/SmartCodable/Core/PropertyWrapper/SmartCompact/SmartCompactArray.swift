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
        
        
        // Scalar decoding in SmartJSONDecoder may return a default for a malformed
        // element. Compact arrays must skip that element, not append the default.
        let decodeValue: () -> Any? = {
            if T.self is any TypeTransformable.Type {
                guard let element = try? container.superDecoder() else { return nil }
                if let impl = element as? JSONDecoderImpl {
                    return Patcher<T>.convertToType(from: impl.json, impl: impl)
                }
                return (T.self as? Decodable.Type).flatMap { try? $0.init(from: element) }
            }
            if let type = T.self as? Decodable.Type {
                guard let element = try? container.superDecoder() else { return nil }
                let decoded: Any?
                if let impl = element as? JSONDecoderImpl {
                    decoded = try? impl.unwrap(as: type)
                } else {
                    decoded = try? type.init(from: element)
                }
                if var model = decoded as? any SmartDecodable {
                    model.didFinishMapping()
                    return model
                }
                return decoded
            }
            return try? container.decode(SmartAnyImpl.self).peel
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
            try container.encode(AnyEncodableBox(value: value))
        }
    }
}
