//
//  _SpecialTreatmentEncoder.swift
//  SmartCodable
//
//  Created by Mccc on 2024/6/3.
//

import Foundation


protocol _JSONStringDictionaryEncodableMarker { }

extension Dictionary: _JSONStringDictionaryEncodableMarker where Key == String, Value: Encodable { }


protocol _SpecialTreatmentEncoder {
    var codingPath: [CodingKey] { get }
    var options: SmartJSONEncoder._Options { get }
    var impl: JSONEncoderImpl { get }
}

extension _SpecialTreatmentEncoder {
    @inline(__always)
    func wrapFloat<F: FloatingPoint & CustomStringConvertible>(_ float: F, for additionalKey: CodingKey?) throws -> JSONValue {
        guard !float.isNaN, !float.isInfinite else {
            if case .convertToString(let posInfString, let negInfString, let nanString) = self.options.nonConformingFloatEncodingStrategy {
                switch float {
                case F.infinity:
                    return .string(posInfString)
                case -F.infinity:
                    return .string(negInfString)
                default:
                    // must be nan in this case
                    return .string(nanString)
                }
            }

            var path = self.codingPath
            if let additionalKey = additionalKey {
                path.append(additionalKey)
            }

            throw EncodingError.invalidValue(float, .init(
                codingPath: path,
                debugDescription: "Unable to encode \(F.self).\(float) directly in JSON."
            ))
        }

        var string = float.description
        if string.hasSuffix(".0") {
            string.removeLast(2)
        }
        return .number(string)
    }

    func wrapEncodable<E: Encodable>(_ encodable: E, for additionalKey: CodingKey?) throws -> JSONValue? {
        switch encodable {
        case let date as Date:
            return try self.wrapDate(date, for: additionalKey)
        case let data as Data:
            return try self.wrapData(data, for: additionalKey)
        case let url as URL:
            return .string(url.absoluteString)
        case let decimal as Decimal:
            return .number(decimal.description)
        case let object as _JSONStringDictionaryEncodableMarker:
            return try self.wrapObject(object as! [String: Encodable], for: additionalKey)
        default:
            
            impl.cache.cacheSnapshot(for: E.self, codingPath: codingPath)
            
            let encoder = self.getEncoder(for: additionalKey)
            try encodable.encode(to: encoder)
            impl.cache.removeSnapshot(for: E.self)

            // If it is modified by SmartFlat, you need to encode to the upper layer to restore the data.
            if encodable is FlatType {
                if let object = encoder.value?.object {
                    for (key, value) in object {
                        self.impl.object?.set(value, for: key)
                    }
                    return nil
                }
            }
        
            return encoder.value
        }
    }

    func wrapDate(_ date: Date, for additionalKey: CodingKey?) throws -> JSONValue {
        
        if let value = impl.cache.tranform(from: date, with: additionalKey, codingPath: codingPath) {
            return value
        }

        switch self.options.dateEncodingStrategy {
        case .deferredToDate:
            let encoder = self.getEncoder(for: additionalKey)
            try date.encode(to: encoder)
            return encoder.value ?? .null

        case .secondsSince1970:
            return .number(date.timeIntervalSince1970.description)

        case .millisecondsSince1970:
            return .number((date.timeIntervalSince1970 * 1000).description)

        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                return .string(_iso8601Formatter.string(from: date))
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }

        case .formatted(let formatter):
            return .string(formatter.string(from: date))

        case .custom(let closure):
            let encoder = self.getEncoder(for: additionalKey)
            try closure(date, encoder)
            // The closure didn't encode anything. Return the default keyed container.
            return encoder.value ?? .object([:])
        @unknown default:
            let encoder = self.getEncoder(for: additionalKey)
            try date.encode(to: encoder)
            return encoder.value ?? .null
        }
    }

    func wrapData(_ data: Data, for additionalKey: CodingKey?) throws -> JSONValue {
        switch self.options.dataEncodingStrategy {
        case .base64:
            let base64 = data.base64EncodedString()
            return .string(base64)
        }
    }

    func wrapObject(_ object: [String: Encodable], for additionalKey: CodingKey?) throws -> JSONValue {
        var baseCodingPath = self.codingPath
        if let additionalKey = additionalKey {
            baseCodingPath.append(additionalKey)
        }
        var result = [String: JSONValue]()
        result.reserveCapacity(object.count)

        try object.forEach { (key, value) in
            var elemCodingPath = baseCodingPath
            elemCodingPath.append(_JSONKey(stringValue: key, intValue: nil))
            let encoder = JSONEncoderImpl(options: self.options, codingPath: elemCodingPath)

            result[key] = try encoder.wrapUntyped(value)
        }

        return .object(result)
    }

    func getEncoder(for additionalKey: CodingKey?) -> JSONEncoderImpl {
        if let additionalKey = additionalKey {
            var newCodingPath = self.codingPath
            newCodingPath.append(additionalKey)
            return JSONEncoderImpl(options: self.options, codingPath: newCodingPath, cache: impl.cache)
        }
        return self.impl
    }
}


extension _SpecialTreatmentEncoder {
    internal func _converted(_ key: CodingKey) -> CodingKey {
        
        var newKey = key
        
        var useMappedKeys = false
        if let key = CodingUserInfoKey.useMappedKeys {
            useMappedKeys = impl.userInfo[key] as? Bool ?? false
        }
            
        if let objectType = impl.cache.findSnapShot(with: impl.codingPath)?.objectType {
            if let mappings = objectType.mappingForKey() {
                for mapping in mappings {
                    if mapping.to.stringValue == newKey.stringValue {
                        if useMappedKeys, let first = mapping.from.first {
                            newKey = _JSONKey.init(stringValue: first, intValue: nil)
                        } else {
                            newKey = mapping.to
                        }
                    }
                }
            }
        }
        
        switch self.options.keyEncodingStrategy {
        case .toSnakeCase:
            let newKeyString = SmartJSONEncoder.SmartKeyEncodingStrategy._convertToSnakeCase(newKey.stringValue)
            return _JSONKey(stringValue: newKeyString, intValue: newKey.intValue)
        case .firstLetterLower:
            let newKeyString = SmartJSONEncoder.SmartKeyEncodingStrategy._convertFirstLetterToLowercase(newKey.stringValue)
            return _JSONKey(stringValue: newKeyString, intValue: newKey.intValue)
        case .firstLetterUpper:
            let newKeyString = SmartJSONEncoder.SmartKeyEncodingStrategy._convertFirstLetterToUppercase(newKey.stringValue)
            return _JSONKey(stringValue: newKeyString, intValue: newKey.intValue)
        case .useDefaultKeys:
            return newKey
        }
    }
}
