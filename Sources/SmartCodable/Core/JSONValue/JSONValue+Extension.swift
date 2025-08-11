//
//  JSONValue+Extension.swift
//  SmartCodable
//
//  Created by Mccc on 2024/5/23.
//

import Foundation

extension JSONValue {
        
    var object: [String: JSONValue]? {
        switch self {
        case .object(let v):
            return v
        default:
            return nil
        }
    }
    
    var array: [JSONValue]? {
        switch self {
        case .array(let v):
            return v
        default:
            return nil
        }
    }
    
    var peel: Any {
        switch self {
        case .array(let v):
            return v.peel
        case .bool(let v):
            return v
        case .number(let v):
            if let number = NSNumber.fromJSONNumber(v) {
                return number
//                return number.toBestSwiftType
            } else {
                return v // fallback to string
            }
        case .string(let v):
            return v
        case .object(let v):
            return v.peel
        case .null:
            return NSNull()
        }
    }
}

extension Dictionary where Key == String, Value == JSONValue {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    var peel: [String: Any] {
        mapValues { $0.peel }
    }
}
extension Array where Element == JSONValue {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    var peel: [Any] {
        map { $0.peel }
    }
}

extension Array where Element == [String: JSONValue] {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    var peel: [Any] {
        map { $0.peel }
    }
}
