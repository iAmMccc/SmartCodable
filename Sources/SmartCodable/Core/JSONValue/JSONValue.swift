//
//  JSONValue.swift
//  SmartCodable
//
//  Created by Mccc on 2024/5/17.
//

import Foundation
enum JSONValue: Equatable {
    case string(String)
    case number(String)
    case bool(Bool)
    case null

    case array([JSONValue])
    case object([String: JSONValue])
    
    
    static func make(_ value: Any?) -> Self? {
        
        guard let value = value else { return nil }
        
        if let jsonValue = value as? JSONValue {
            return jsonValue
        }
        
        switch value {
        case is NSNull:
            return .null
        case let string as String:
            return .string(string)
        case let number as NSNumber:
            
            // 判断是否为 Bool 类型
            let cfType = CFNumberGetType(number)
            if cfType == .charType {
                return .bool(number.boolValue)
            } else {
                return .number(number.stringValue)
            }
            
        case let array as [Any]:
            let jsonArray = array.compactMap { make($0) }
            return .array(jsonArray)
        case let dictionary as [String: Any]:
            let jsonObject = dictionary.compactMapValues { make($0) }
            return .object(jsonObject)
        default:
            return nil
        }
    }
    
    func toFoundation() -> Any {
        switch self {
        case .null:
            return NSNull()
        case .bool(let b):
            return b
        case .number(let n):
            /// 直接返回number即可。
            if let number = NSNumber.fromJSONNumber(n) {
                return number
            } else {
                return n
            }
            
        case .string(let s):
            return s
        case .array(let arr):
            return arr.map { $0.toFoundation() }
        case .object(let dict):
            return dict.mapValues { $0.toFoundation() }
        }
    }
}


extension JSONValue {
    var isValue: Bool {
        switch self {
        case .array, .object:
            return false
        case .null, .number, .string, .bool:
            return true
        }
    }
    
    var isNull: Bool {
        switch self {
        case .null:
            return true
        case .array, .object, .number, .string, .bool:
            return false
        }
    }
    
    var isContainer: Bool {
        switch self {
        case .array, .object:
            return true
        case .null, .number, .string, .bool:
            return false
        }
    }
}

extension JSONValue {
    var debugDataTypeDescription: String {
        switch self {
        case .array:
            return "’Array‘"
        case .bool:
            return "’Bool‘"
        case .number:
            return "’Number‘"
        case .string:
            return "‘String’"
        case .object:
            return "’Dictionary‘"
        case .null:
            return "’null‘"
        }
    }
}


extension NSNumber {
    static func fromJSONNumber(_ string: String) -> NSNumber? {
        let decIndex = string.firstIndex(of: ".")
        let expIndex = string.firstIndex(of: "e")
        let isInteger = decIndex == nil && expIndex == nil
        let isNegative = string.utf8[string.utf8.startIndex] == UInt8(ascii: "-")
        let digitCount = string[string.startIndex..<(expIndex ?? string.endIndex)].count
        
        // Try Int64() or UInt64() first
        if isInteger {
            if isNegative {
                if digitCount <= 19, let intValue = Int64(string) {
                    return NSNumber(value: intValue)
                }
            } else {
                if digitCount <= 20, let uintValue = UInt64(string) {
                    return NSNumber(value: uintValue)
                }
            }
        }

        var exp = 0
        
        if let expIndex = expIndex {
            let expStartIndex = string.index(after: expIndex)
            if let parsed = Int(string[expStartIndex...]) {
                exp = parsed
            }
        }
        
        // Decimal holds more digits of precision but a smaller exponent than Double
        // so try that if the exponent fits and there are more digits than Double can hold
        if digitCount > 17, exp >= -128, exp <= 127, let decimal = Decimal(string: string), decimal.isFinite {
            return NSDecimalNumber(decimal: decimal)
        }
        
        // Fall back to Double() for everything else
        if let doubleValue = Double(string), doubleValue.isFinite {
            return NSNumber(value: doubleValue)
        }
        
        return nil
    }
    
    /// 尝试将 NSNumber 转换为最合适的 Swift 基础类型（Int64、Double、Bool、Decimal 等）
    var toBestSwiftType: Any {
        if let decimal = self as? NSDecimalNumber {
            return decimal.decimalValue // 返回 Swift 的 Decimal 类型更自然
        }

        switch CFNumberGetType(self) {
        case .charType:
            return self.boolValue

        case .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type:
            let int64 = self.int64Value
            if int64 >= Int.min && int64 <= Int.max {
                return Int(int64)
            } else {
                return int64 // fallback
            }

        case .floatType, .float32Type, .float64Type, .doubleType:
            return self.doubleValue

        default:
            return self // fallback 为原始 NSNumber
        }
    }
}
