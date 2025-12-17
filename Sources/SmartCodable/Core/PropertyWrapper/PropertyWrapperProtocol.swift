//
//  PropertyWrapperProtocol.swift
//  SmartCodable
//
//  Created by qixin on 2025/4/9.
//

import Foundation

/**
 Protocol defining requirements for types that can publish wrapped Codable values.
 
 Provides a unified interface for any type conforming to this protocol.
 - WrappedValue: The generic type that must conform to Codable
 - createInstance: Attempts to create an instance from any value
 */
public protocol PropertyWrapperable {
    associatedtype WrappedValue
    
    var wrappedValue: WrappedValue { get }
    
    init(wrappedValue: WrappedValue)
    
    static var wrappedSmartDecodableType: SmartDecodable.Type? { get }

    static func createInstance(with value: Any) -> Self?
    
    /**
     Callback invoked when the wrapped value finishes decoding/mapping.
     
     - Returns: An optional new instance of the wrapper with processed value
     - Note: Primarily used by property wrappers containing types conforming to SmartDecodable
     */
    func wrappedValueDidFinishMapping() -> Self?
}

public extension PropertyWrapperable {
    static var wrappedSmartDecodableType: SmartDecodable.Type? {

        let valueType = WrappedValue.self

        // 1️⃣ WrappedValue 本身是 SmartDecodable
        if let smart = valueType as? SmartDecodable.Type {
            return smart
        }

        // 2️⃣ WrappedValue 是 Optional<SmartDecodable>
        if let optionalType = valueType as? _OptionalType.Type,
           let smart = optionalType.wrappedType as? SmartDecodable.Type {
            return smart
        }

        return nil
    }
}

protocol _OptionalType {
    static var wrappedType: Any.Type { get }
}

extension Optional: _OptionalType {
    static var wrappedType: Any.Type {
        Wrapped.self
    }
}

// ============================================================
// 统一为所有 PropertyWrapperable 提供 Equatable / Hashable 支持
/// 为遵循 PropertyWrapperable 的泛型 wrapper 提供默认的 Equatable 实现
extension PropertyWrapperable where WrappedValue: Equatable, Self: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

/// 为遵循 PropertyWrapperable 的泛型 wrapper 提供默认的 Hashable 实现
extension PropertyWrapperable where WrappedValue: Hashable, Self: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

// ============================================================
// 泛型 wrapper 的空声明扩展
// 由于 Swift 泛型限制，编译器无法自动将泛型 wrapper 标记为 Equatable / Hashable
// 所以必须显式声明遵循协议，同时条件约束 WrappedValue

extension SmartFlat: Equatable where T: Equatable {}
extension SmartFlat: Hashable where T: Hashable {}

extension SmartIgnored: Equatable where T: Equatable {}
extension SmartIgnored: Hashable where T: Hashable {}

extension SmartAny: Equatable where T: Equatable {}
extension SmartAny: Hashable where T: Hashable {}



// 非泛型
// 因为非泛型 wrapper 的类型固定，不依赖泛型约束，所以可以直接声明协议遵循
extension SmartDate: Equatable {}
extension SmartDate: Hashable {}

extension SmartHexColor: Equatable {
    public static func == (lhs: SmartHexColor, rhs: SmartHexColor) -> Bool {
        switch (lhs.wrappedValue?.rgbaComponents, rhs.wrappedValue?.rgbaComponents) {
        case let (l?, r?):
            return l.r == r.r && l.g == r.g && l.b == r.b && l.a == r.a
        case (nil, nil):
            return true
        default:
            return false
        }
    }
}
extension SmartHexColor: Hashable {
    public func hash(into hasher: inout Hasher) {
        if let components = wrappedValue?.rgbaComponents {
            hasher.combine(components.r)
            hasher.combine(components.g)
            hasher.combine(components.b)
            hasher.combine(components.a)
        }
    }
}
