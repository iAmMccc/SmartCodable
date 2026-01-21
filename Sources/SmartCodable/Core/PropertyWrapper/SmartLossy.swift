//
//  SmartLossy.swift
//  SmartCodable
//
//  Created by Mccc on 2026/1/21.
//

import Foundation
@propertyWrapper
public struct SmartLossy<Element: Codable>: PropertyWrapperable {

    public var wrappedValue: [Element]

    public init(wrappedValue: [Element]) {
        self.wrappedValue = wrappedValue
    }
    
    public func wrappedValueDidFinishMapping() -> SmartLossy<Element>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartLossy(wrappedValue: temp as! [Element])
        }
        return nil
    }
    
    /// Creates an instance from any value if possible
    public static func createInstance(with value: Any) -> SmartLossy? {
        if let value = value as? [Element] {
            return SmartLossy(wrappedValue: value)
        }
        return nil
    }
}


extension SmartLossy: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Element] = []

        while !container.isAtEnd {
            do {
                let value = try container.decode(Element.self)
                result.append(value)
            } catch {
                // 必须消费掉当前元素，让Index加1.
                _ = try? container.decode(DummyDecodable.self)
            }
        }

        self.wrappedValue = result
    }
    
    // MARK: - Encode（正常编码）
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for value in wrappedValue {
            try container.encode(value)
        }
    }
}

private struct DummyDecodable: Decodable {}
