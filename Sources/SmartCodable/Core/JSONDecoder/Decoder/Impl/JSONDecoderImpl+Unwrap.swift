//
//  JSONDecoderImpl+unwrap.swift
//  SmartCodable
//
//  Created by Mccc on 2024/5/21.
//

import Foundation

fileprivate protocol _JSONStringDictionaryDecodableMarker {
    static var elementType: Decodable.Type { get }
}

extension Dictionary: _JSONStringDictionaryDecodableMarker where Key == String, Value: Decodable {
    static var elementType: Decodable.Type { return Value.self }
}

extension JSONDecoderImpl {
    // MARK: Special case handling
    
    func unwrap<T: Decodable>(as type: T.Type) throws -> T {
        if type == Date.self {
            return try self.unwrapDate() as! T
        }
        if type == Data.self {
            return try self.unwrapData() as! T
        }
        if type == URL.self {
            return try self.unwrapURL() as! T
        }
        if type == Decimal.self {
            return try self.unwrapDecimal() as! T
        }
        if type == CGFloat.self {
            return try unwrapCGFloat() as! T
        }
        
        if type is _JSONStringDictionaryDecodableMarker.Type {
            return try self.unwrapDictionary(as: type)
        }
        
        cache.cacheSnapshot(for: type, codingPath: codingPath)
        let decoded = try type.init(from: self)
        cache.removeSnapshot(for: type)
        return decoded
    }
    
    func unwrapFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>(
        from value: JSONValue, for additionalKey: CodingKey? = nil, as type: T.Type) -> T? {
            
            if let tranformer = cache.valueTransformer(for: additionalKey, codingPath: codingPath) {
                guard let decoded = tranformer.tranform(value: value) as? T else { return nil }
                return decoded
            }
            
            if case .number(let number) = value {
                guard let floatingPoint = T(number), floatingPoint.isFinite else { return nil }
                return floatingPoint
            }
            
            if case .string(let string) = value,
               case .convertFromString(let posInfString, let negInfString, let nanString) = self.options.nonConformingFloatDecodingStrategy {
                if string == posInfString {
                    return T.infinity
                } else if string == negInfString {
                    return -T.infinity
                } else if string == nanString {
                    return T.nan
                }
            }

            return nil
        }
    
    func unwrapFixedWidthInteger<T: FixedWidthInteger>(
        from value: JSONValue, for additionalKey: CodingKey? = nil, as type: T.Type) -> T? {
            
            if let tranformer = cache.valueTransformer(for: additionalKey, codingPath: codingPath) {
                return tranformer.tranform(value: value) as? T
            }
            
            guard case .number(let number) = value else { return nil }
            
            // this is the fast pass. Number directly convertible to Integer
            if let integer = T(number) {
                return integer
            }
            
            // this is the really slow path... If the fast path has failed. For example for "34.0" as
            // an integer, we try to go through NSNumber
            if let nsNumber = NSNumber.fromJSONNumber(number) {
                if type == UInt8.self, NSNumber(value: nsNumber.uint8Value) == nsNumber {
                    return nsNumber.uint8Value as? T
                }
                if type == Int8.self, NSNumber(value: nsNumber.int8Value) == nsNumber {
                    return nsNumber.int8Value as? T
                }
                if type == UInt16.self, NSNumber(value: nsNumber.uint16Value) == nsNumber {
                    return nsNumber.uint16Value as? T
                }
                if type == Int16.self, NSNumber(value: nsNumber.int16Value) == nsNumber {
                    return nsNumber.int16Value as? T
                }
                if type == UInt32.self, NSNumber(value: nsNumber.uint32Value) == nsNumber {
                    return nsNumber.uint32Value as? T
                }
                if type == Int32.self, NSNumber(value: nsNumber.int32Value) == nsNumber {
                    return nsNumber.int32Value as? T
                }
                if type == UInt64.self, NSNumber(value: nsNumber.uint64Value) == nsNumber {
                    return nsNumber.uint64Value as? T
                }
                if type == Int64.self, NSNumber(value: nsNumber.int64Value) == nsNumber {
                    return nsNumber.int64Value as? T
                }
                if type == UInt.self, NSNumber(value: nsNumber.uintValue) == nsNumber {
                    return nsNumber.uintValue as? T
                }
                if type == Int.self, NSNumber(value: nsNumber.intValue) == nsNumber {
                    return nsNumber.intValue as? T
                }
            }
            return nil
        }
    
    func unwrapBoolValue(from value: JSONValue, for additionalKey: CodingKey? = nil) -> Bool? {
        
        if let tranformer = cache.valueTransformer(for: additionalKey, codingPath: codingPath) {
            return tranformer.tranform(value: value) as? Bool
        }
        
        guard case .bool(let bool) = value else { return nil }
        return bool
    }
    
    func unwrapStringValue(from value: JSONValue, for additionalKey: CodingKey? = nil) -> String? {
        
        if let tranformer = cache.valueTransformer(for: additionalKey, codingPath: codingPath) {
            return tranformer.tranform(value: value) as? String
        }
        
        guard case .string(let string) = value else { return nil }
        return string
    }
}

extension JSONDecoderImpl {
    private func unwrapDate() throws -> Date {
        
        if let tranformer = cache.valueTransformer(for: codingPath.last, codingPath: codingPath) {
            if let decoded = tranformer.tranform(value: json) as? Date {
                return decoded
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Date is not valid , unknown anomaly"))
            }
        }
        
        let container = SingleValueContainer(impl: self, codingPath: codingPath, json: json)

        
        if let dateDecodingStrategy = self.options.dateDecodingStrategy  {
            switch dateDecodingStrategy {
            case .deferredToDate:
                return try Date(from: self)
                
            case .secondsSince1970:
                let double = try container.decode(Double.self)
                return Date(timeIntervalSince1970: double)
                
            case .millisecondsSince1970:
                let double = try container.decode(Double.self)
                return Date(timeIntervalSince1970: double / 1000.0)
                
            case .iso8601:
                if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                    let string = try container.decode(String.self)
                    guard let date = _iso8601Formatter.date(from: string) else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
                    }
                    
                    return date
                } else {
                    fatalError("ISO8601DateFormatter is unavailable on this platform.")
                }
                
            case .formatted(let formatter):
                let string = try container.decode(String.self)
                guard let date = formatter.date(from: string) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Date string does not match format expected by formatter."))
                }
                return date
                
            case .custom(let closure):
                return try closure(self)
            @unknown default:
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Date is not valid , unknown anomaly"))
            }
        }
        
        // 如果没有设置策略，使用 DateParser 做兜底解析
        if let (date, _) = DateParser.parse(json.peel) {
            return date
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Unsupported date format: \(json)"))
        }
    }
    
    private func unwrapData() throws -> Data {
        
        if let tranformer = cache.valueTransformer(for: codingPath.last, codingPath: codingPath) {
            if let decoded = tranformer.tranform(value: json) as? Data {
                return decoded
            }
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Data is not valid Base64."))
        }
        
        switch self.options.dataDecodingStrategy {
        case .base64:
            let container = SingleValueContainer(impl: self, codingPath: self.codingPath, json: self.json)
            let string = try container.decode(String.self)
            
            guard let data = Data(base64Encoded: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Data is not valid Base64."))
            }
            
            return data
        }
    }
    
    private func unwrapURL() throws -> URL {
        
        if let tranformer = cache.valueTransformer(for: codingPath.last, codingPath: codingPath) {
            if let decoded = tranformer.tranform(value: json) as? URL {
                return decoded
            }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: self.codingPath,
                                      debugDescription: "Invalid URL string."))
        }
        
        
        let container = SingleValueContainer(impl: self, codingPath: self.codingPath, json: self.json)
        let string = try container.decode(String.self)
        
        guard let url = URL(string: string) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: self.codingPath,
                                      debugDescription: "Invalid URL string."))
        }
        return url
    }
    
    private func unwrapDecimal() throws -> Decimal {
        
        if let tranformer = cache.valueTransformer(for: codingPath.last, codingPath: codingPath) {
            if let decoded = tranformer.tranform(value: json) as? Decimal {
                return decoded
            }
            throw DecodingError.dataCorrupted(.init(
                codingPath: self.codingPath,
                debugDescription: "Parsed JSON number does not fit in \(Decimal.self)."))
        }
        
        guard case .number(let numberString) = self.json else {
            throw DecodingError.typeMismatch(Decimal.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
        }
        
        guard let decimal = Decimal(string: numberString) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: self.codingPath,
                debugDescription: "Parsed JSON number <\(numberString)> does not fit in \(Decimal.self)."))
        }
        
        return decimal
    }
    
    
    private func unwrapCGFloat() throws -> CGFloat {
        if let transformer = cache.valueTransformer(for: codingPath.last, codingPath: codingPath) {
            if let decoded = transformer.tranform(value: json) as? CGFloat {
                return decoded
            }
            throw DecodingError.dataCorrupted(.init(
                codingPath: self.codingPath,
                debugDescription: "Parsed JSON value cannot be transformed to \(CGFloat.self)."))
        }
        
        guard case .number(let numberString) = self.json else {
            throw DecodingError.typeMismatch(CGFloat.self, DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Expected a JSON number for \(CGFloat.self), but found."))
        }
        
        guard let doubleValue = Double(numberString) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: self.codingPath,
                debugDescription: "Parsed JSON number <\(numberString)> is not a valid Double for conversion to \(CGFloat.self)."))
        }
        
        return CGFloat(doubleValue)
    }
    
    
    private func unwrapDictionary<T: Decodable>(as: T.Type) throws -> T {
        guard let dictType = T.self as? (_JSONStringDictionaryDecodableMarker & Decodable).Type else {
            preconditionFailure("Must only be called of T implements _JSONStringDictionaryDecodableMarker")
        }
        
        guard case .object(let object) = self.json else {
            throw DecodingError.typeMismatch([String: JSONValue].self, DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Expected to decode \([String: JSONValue].self) but found \(self.json.debugDataTypeDescription) instead."
            ))
        }
        
        var result = [String: Any]()
        
        for (key, value) in object {
            var newPath = self.codingPath
            newPath.append(_JSONKey(stringValue: key)!)
            let newDecoder = JSONDecoderImpl(
                userInfo: self.userInfo,
                from: value,
                codingPath: newPath,
                options: self.options)
            result[key] = try dictType.elementType.createByDirectlyUnwrapping(from: newDecoder)
        }
        return result as! T
    }
    
    func createTypeMismatchError(type: Any.Type, for additionalKey: CodingKey? = nil, value: JSONValue) -> DecodingError {
        var path = self.codingPath
        if let additionalKey = additionalKey {
            path.append(additionalKey)
        }
        
        return DecodingError.typeMismatch(type, .init(
            codingPath: path,
            debugDescription: "Expected to decode \(type) but found \(value.debugDataTypeDescription) instead."
        ))
    }
}


extension Decodable {
    fileprivate static func createByDirectlyUnwrapping(from decoder: JSONDecoderImpl) throws -> Self {
        if Self.self == URL.self
            || Self.self == Date.self
            || Self.self == Data.self
            || Self.self == Decimal.self
            || Self.self == SmartAnyImpl.self
            || Self.self is _JSONStringDictionaryDecodableMarker.Type
        {
            return try decoder.unwrap(as: Self.self)
        }
        return try Self.init(from: decoder)
    }
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
internal let _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()
