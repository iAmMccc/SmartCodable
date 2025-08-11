//
//  SmartFlat.swift
//  SmartCodable
//
//  Created by Mccc on 2024/6/18.
//


import Foundation

/**
 A property wrapper that provides flat decoding/encoding of values while handling type conversion errors.
 
 Important Notes:
 1. Properties wrapped by property wrappers won't automatically call `didFinishMapping` methods.
 2. Swift's type system can't directly identify the actual type of wrappedValue at runtime,
    so each property wrapper needs to handle this manually.
 */
@propertyWrapper
public struct SmartFlat<T: Codable>: PropertyWrapperable {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    public func wrappedValueDidFinishMapping() -> SmartFlat<T>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartFlat(wrappedValue: temp as! T)
        }
        return nil
    }
    
    /// Creates an instance from any value if possible
    public static func createInstance(with value: Any) -> SmartFlat? {
        if let value = value as? T {
            return SmartFlat(wrappedValue: value)
        }
        return nil
    }
}


extension SmartFlat: Codable {
    
    public init(from decoder: Decoder) throws {
        do {
            wrappedValue = try T(from: decoder)
        } catch  {
            wrappedValue = try Patcher<T>.defaultForType()
        }
    }

    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}



// Used to mark the flat type
protocol FlatType { 
    static var isArray: Bool { get }
}

extension SmartFlat: FlatType {
    /// Determines if the wrapped type is an array
    static var isArray: Bool { T.self is _ArrayMark.Type }
}

/**
 Marker protocol for array types with Decodable elements.
 
 When T is an array with elements conforming to Decodable,
 T.self will be covered by the Array extension, making T.self is _ArrayMark.Type return true.
 */
protocol _ArrayMark { }


/// This extension marks Array types as _ArrayMark when their Element conforms to Decodable.
/// This means only arrays with Decodable elements will be marked as _ArrayMark.
extension Array: _ArrayMark where Element: Decodable { }


