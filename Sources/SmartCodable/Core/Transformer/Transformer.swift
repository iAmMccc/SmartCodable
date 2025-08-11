//
//  SmartKeyTransformer.swift
//  SmartCodable
//
//  Created by Mccc on 2024/4/9.
//

import Foundation


/// Resolve the mapping relationship of keys
public struct SmartKeyTransformer {
    var from: [String]
    var to: CodingKey
}

infix operator <---
/// Map the data fields corresponding to “from” to model properties corresponding to “to”.
public func <---(to: CodingKey, from: String) -> SmartKeyTransformer {
    to <--- [from]
}

/// When multiple valid fields are mapped to the same property, the first one is used first.
public func <---(to: CodingKey, from: [String]) -> SmartKeyTransformer {
    SmartKeyTransformer(from: from, to: to)
}




public struct SmartValueTransformer {
    var location: CodingKey
    var performer: any ValueTransformable
    public init(location: CodingKey, performer: any ValueTransformable) {
        self.location = location
        self.performer = performer
    }
    
    /// Transforms a JSON value using the appropriate transformer
    /// - Parameters:
    ///   - value: The JSON value to transform
    ///   - key: The associated coding key (if available)
    /// - Returns: The transformed value or nil if no transformer applies
    func transformFromJSON(_ value: JSONValue) -> Any? {
        return performer.transformFromJSON(value.peel)
    }
}


public protocol ValueTransformable {
    associatedtype Object
    associatedtype JSON
    
    /// transform from ’json‘ to ’object‘
    func transformFromJSON(_ value: Any) -> Object?
    
    /// transform to ‘json’ from ‘object’
    func transformToJSON(_ value: Object) -> JSON?
}


public func <---(location: CodingKey, performer: any ValueTransformable) -> SmartValueTransformer {
    SmartValueTransformer.init(location: location, performer: performer)
}



/** Fast Transformer
 static func mappingForValue() -> [SmartValueTransformer]? {
     [
         CodingKeys.name <--- FastTransformer<String, String>(fromJSON: { json in
             "abc"
         }, toJSON: { object in
             "123"
         }),
         CodingKeys.subModel <--- FastTransformer<TestEnum, String>(fromJSON: { json in
             TestEnum.man
         }, toJSON: { object in
             object?.rawValue
         }),
     ]
 }
 */
public struct FastTransformer<Object, JSON>: ValueTransformable {
    
    private let fromJSON: (JSON?) -> Object?
    private let toJSON: ((Object?) -> JSON?)?
    
    
    /// 便捷的转换器
    /// - Parameters:
    ///   - fromJSON: json 转 object
    ///   - toJSON:  object 转 json， 如果不需要转json，可以不实现。
    public init(fromJSON: @escaping (JSON?) -> Object?, toJSON: ((Object?) -> JSON?)? = nil) {
        self.fromJSON = fromJSON
        self.toJSON = toJSON
    }
    
    public func transformFromJSON(_ value: Any) -> Object? {
        return fromJSON(value as? JSON)
    }
    
    public func transformToJSON(_ value: Object) -> JSON? {
        return toJSON?(value)
    }
}
