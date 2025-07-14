//
//  SmartAny.swift
//  SmartCodable
//
//  Created by Mccc on 2023/12/1.
//

import Foundation

/// SmartAny represents any type for Codable parsing, which can be simply understood as Any.
///
/// Codable does not support parsing of the Any type. Consequently, corresponding types like dictionary [String: Any], array [Any], and [[String: Any]] cannot be parsed.
/// By wrapping it with SmartAny, it achieves the purpose of enabling parsing for Any types.
///
/// To retrieve the original value, call '.peel' to unwrap it.
enum SmartAnyImpl {
    
    /// In Swift, NSNumber is a composite type that can accommodate various numeric types:
    ///  - All integer types: Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64
    ///  - All floating-point types: Float, Double
    ///  - Boolean type: Bool
    ///
    /// Due to its dynamic nature, it can store different types of numbers and query their specific types at runtime.
    /// This provides a degree of flexibility but also sacrifices the type safety and performance advantages of Swift's native types.
    ///
    /// In the initial implementation, these basic data types were handled separately. For example:
    ///  - case bool(Bool)
    ///  - case double(Double), cgFloat(CGFloat), float(Float)
    ///  - case int(Int), int8(Int8), int16(Int16), int32(Int32), int64(Int64)
    ///  - case uInt(UInt), uInt8(UInt8), uInt16(UInt16), uInt32(UInt32), uInt64(UInt64)
    /// However, during parsing, a situation arises: the data type is forcibly specified, losing the flexibility of NSNumber. For instance, `as? Double` will fail when the data is 5.
    case number(NSNumber)
    case string(String)
    case dict([String: SmartAnyImpl])
    case array([SmartAnyImpl])
    case null(NSNull)
    
    
    public init(from value: Any) {
        self = .convertToSmartAny(value)
    }
}

extension Dictionary where Key == String {
    /// Converts from [String: Any] type to [String: SmartAny]
    internal var cover: [String: SmartAnyImpl] {
        mapValues { SmartAnyImpl(from: $0) }
    }
    
    /// Unwraps if it exists, otherwise returns itself.
    internal var peelIfPresent: [String: Any] {
        if let dict = self as? [String: SmartAnyImpl] {
            return dict.peel
        } else {
            return self
        }
    }
}

extension Array {
    internal var cover: [ SmartAnyImpl] {
        map { SmartAnyImpl(from: $0) }
    }
    
    /// Unwraps if it exists, otherwise returns itself.
    internal var peelIfPresent: [Any] {
        if let arr = self as? [[String: SmartAnyImpl]] {
            return arr.peel
        } else if let arr = self as? [SmartAnyImpl] {
            return arr.peel
        } else {
            return self
        }
    }
}


extension Dictionary where Key == String, Value == SmartAnyImpl {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    internal var peel: [String: Any] {
        mapValues { $0.peel }
    }
}
extension Array where Element == SmartAnyImpl {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    internal var peel: [Any] {
        map { $0.peel }
    }
}

extension Array where Element == [String: SmartAnyImpl] {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    public var peel: [Any] {
        map { $0.peel }
    }
}


extension SmartAnyImpl {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    public var peel: Any {
        switch self {
        case .number(let v):  return v
        case .string(let v):  return v
        case .dict(let v):    return v.peel
        case .array(let v):   return v.peel
        case .null:           return NSNull()
        }
    }
}



extension SmartAnyImpl: Codable {
    public init(from decoder: Decoder) throws {
        
        
        guard let decoder = decoder as? JSONDecoderImpl else {
            throw DecodingError.typeMismatch(
                SmartAnyImpl.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected \(Self.self) value, but decoder type mismatch"
                )
            )
        }
        
        guard let containerAny = try? decoder.singleValueContainer(),
              let container = containerAny as? JSONDecoderImpl.SingleValueContainer else {
            throw DecodingError.typeMismatch(
                SmartAnyImpl.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected \(Self.self) value, but container type mismatch"
                )
            )
        }
        
        
       
        if container.decodeNil() {
            self = .null(NSNull())
        } else if let value = try? decoder.unwrapSmartAny() {
            self = value
        } else {
            throw DecodingError.typeMismatch(SmartAnyImpl.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "Expected \(Self.self) value，but an exception occurred！Please report this issue（请上报该问题）")
            )
        }
    }
        
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .string(let value):
            try container.encode(value)
        case .dict(let dictValue):
            try container.encode(dictValue)
        case .array(let arrayValue):
            try container.encode(arrayValue)
        case .number(let value):
            /**
             Swift为了与Objective-C的兼容性，提供了自动桥接功能，允许Swift的数值类型和NSNumber之间的无缝转换。这包括：
             所有的整数类型：Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64
             所有的浮点类型：Float, Double
             布尔类型：Bool
             */
            
            if value === kCFBooleanTrue as NSNumber || value === kCFBooleanFalse as NSNumber {
                if let bool = value as? Bool {
                    try container.encode(bool)
                }  
            } else if let double = value as? Double {
                try container.encode(double)
            } else if let float = value as? Float {
                try container.encode(float)
            } else if let cgfloat = value as? CGFloat {
                try container.encode(cgfloat)
            } else if let int = value as? Int {
                try container.encode(int)
            } else if let int8 = value as? Int8 {
                try container.encode(int8)
            } else if let int16 = value as? Int16 {
                try container.encode(int16)
            } else if let int32 = value as? Int32 {
                try container.encode(int32)
            } else if let int64 = value as? Int64 {
                try container.encode(int64)
            } else if let uInt = value as? UInt {
                try container.encode(uInt)
            } else if let uInt8 = value as? UInt8 {
                try container.encode(uInt8)
            } else if let uInt16 = value as? UInt16 {
                try container.encode(uInt16)
            } else if let uInt32 = value as? UInt32 {
                try container.encode(uInt32)
            } else if let uInt64 = value as? UInt64 {
                try container.encode(uInt64)
            } else {
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "NSNumber contains unsupported type"))
            }
        }
    }
}


extension SmartAnyImpl {
    private static func convertToSmartAny(_ value: Any) -> SmartAnyImpl {
        switch value {
        case let v as NSNumber:      return .number(v)
        case let v as String:        return .string(v)
        case let v as [String: Any]: return .dict(v.mapValues { convertToSmartAny($0) })
        case let v as SmartCodable:
            if let dict = v.toDictionary() {
                return .dict(dict.mapValues { convertToSmartAny($0) })
            }
        case let v as [Any]:         return .array(v.map { convertToSmartAny($0) })
        case is NSNull:              return .null(NSNull())
        default:                     break
        }
        
        return .null(NSNull())
    }
}


extension JSONDecoderImpl {
    fileprivate func unwrapSmartAny() throws -> SmartAnyImpl {
        
        if let tranformer = cache.valueTransformer(for: codingPath.last, codingPath: codingPath) {
            if let decoded = tranformer.tranform(value: json) as? SmartAnyImpl {
                return decoded
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: self.codingPath,
                                          debugDescription: "Invalid SmartAny."))
            }
        }
        
        let container = SingleValueContainer(impl: self, codingPath: self.codingPath, json: self.json)
        
        
        switch json {
        case .null:
            return .null(NSNull())
        case .string(let string):
            return .string(string)
        case .bool(let bool):
            return .number(bool as NSNumber)
        case .object(_):
            if let temp = container.decodeIfPresent([String: SmartAnyImpl].self) {
                return .dict(temp)
            }
        case .array(_):
            if let temp = container.decodeIfPresent([SmartAnyImpl].self) {
                return .array(temp)
            }
        case .number(let number):
            if number.contains(".") { // 浮点数
                if number.contains("e") { // 检查字符串中是否包含字符 e，这表示数字可能以科学计数法表示
                    if let temp = container.decodeIfPresent(Decimal.self) as? NSNumber {
                        return .number(temp)
                    }
                } else {
                    if let temp = container.decodeIfPresent(Double.self) as? NSNumber {
                        return .number(temp)
                    }
                }
            } else {
                if let _ = Int64(number) { // 在Int64的范围内
                    if let temp = container.decodeIfPresent(Int8.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(UInt8.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(Int16.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(UInt16.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(Int32.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(UInt32.self) as? NSNumber {
                        return .number(temp)
                    }  else if let temp = container.decodeIfPresent(Int64.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(UInt64.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(Int.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(UInt.self) as? NSNumber {
                        return .number(temp)
                    }
                } else {
                    return .string(number)
                }
            }
        }
 
        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: self.codingPath,
                                  debugDescription: "Invalid SmartAny."))
    }
}

extension JSONDecoderImpl.SingleValueContainer {
    
    fileprivate func decodeIfPresent(_: Bool.Type) -> Bool? {
        guard case .bool(let bool) = self.value else {
            return nil
        }

        return bool
    }

    fileprivate func decodeIfPresent(_: String.Type) -> String? {
        guard case .string(let string) = self.value else {
            return nil
        }
        return string
    }

    fileprivate func decodeIfPresent(_: Double.Type) -> Double? {
        decodeIfPresentFloatingPoint()
    }

    fileprivate func decodeIfPresent(_: Float.Type) -> Float? {
        decodeIfPresentFloatingPoint()
    }

    fileprivate func decodeIfPresent(_: Int.Type) -> Int? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: Int8.Type) -> Int8? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: Int16.Type) -> Int16? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: Int32.Type) -> Int32? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: Int64.Type) -> Int64? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: UInt.Type) -> UInt? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: UInt8.Type) -> UInt8? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: UInt16.Type) -> UInt16? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: UInt32.Type) -> UInt32? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: UInt64.Type) -> UInt64? {
        decodeIfPresentFixedWidthInteger()
    }
    
    fileprivate func decodeIfPresent<T>(_ type: T.Type) -> T? where T: Decodable {
        if let decoded: T = try? self.impl.unwrap(as: type) {
            return decoded
        } else {
            return nil
        }
    }
    
    @inline(__always) private func decodeIfPresentFixedWidthInteger<T: FixedWidthInteger>() -> T? {
        guard let decoded = self.impl.unwrapFixedWidthInteger(from: self.value, as: T.self) else {
            return nil
        }
        return decoded
    }

    @inline(__always) private func decodeIfPresentFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() -> T? {
        
        guard let decoded = self.impl.unwrapFloatingPoint(from: self.value, as: T.self) else {
            return nil
        }
        return decoded
    }
}
