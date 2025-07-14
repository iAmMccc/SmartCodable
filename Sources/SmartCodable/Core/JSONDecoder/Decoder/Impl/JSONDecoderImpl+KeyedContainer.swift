//
//  JSONDecoderImpl+KeyedContainer.swift
//  SmartCodable
//
//  Created by Mccc on 2024/5/17.
//

import Foundation
extension JSONDecoderImpl {
    /// A container that provides a view into a JSON dictionary and decodes values from it
    struct KeyedContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
        typealias Key = K
        
        let impl: JSONDecoderImpl
        let codingPath: [CodingKey]
        let dictionary: [String: JSONValue]
        
        init(impl: JSONDecoderImpl, codingPath: [CodingKey], dictionary: [String: JSONValue]) {
            
            self.codingPath = codingPath
            
            self.dictionary = _convertDictionary(dictionary, impl: impl)
            // The transformation of the dictionary does not affect the structure,
            // but only adds a new field to the data corresponding to the current container.
            // No impl changes are required
            self.impl = impl
        }
        
        var allKeys: [K] {
            self.dictionary.keys.compactMap { K(stringValue: $0) }
        }
        
        func contains(_ key: K) -> Bool {
            if let _ = dictionary[key.stringValue] {
                return true
            }
            return false
        }
        
        func decodeNil(forKey key: K) throws -> Bool {
            guard let value = getValue(forKey: key) else {
                throw DecodingError._keyNotFound(key: key, codingPath: self.codingPath)
            }
            return value == .null
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws
        -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey
        {
            try decoderForKey(key).container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
            try decoderForKey(key).unkeyedContainer()
        }
        
        func superDecoder() throws -> Decoder {
            return decoderForKeyNoThrow(_JSONKey.super)
        }
        
        func superDecoder(forKey key: K) throws -> Decoder {
            return decoderForKeyNoThrow(key)
        }
        
        private func decoderForKey<LocalKey: CodingKey>(_ key: LocalKey) throws -> JSONDecoderImpl {
            
            guard let value = getValue(forKey: key) else {
                throw DecodingError._keyNotFound(key: key, codingPath: self.codingPath)
            }
            
            var newPath = self.codingPath
            newPath.append(key)
            
            return JSONDecoderImpl(userInfo: self.impl.userInfo, from: value, codingPath: newPath, options: self.impl.options)
        }
        
        
        private func decoderForKeyCompatibleForJson<LocalKey: CodingKey, T>(_ key: LocalKey, type: T.Type) throws -> JSONDecoderImpl {
            guard let value = getValue(forKey: key) else {
                throw DecodingError._keyNotFound(key: key, codingPath: self.codingPath)
            }
            var newPath = self.codingPath
            newPath.append(key)
            
            var newImpl = JSONDecoderImpl(userInfo: self.impl.userInfo, from: value, codingPath: newPath, options: self.impl.options)
            
            // If the new parser is not a parse Model,
            // it inherits the cache from the previous one.
            if !(type is SmartDecodable.Type) {
                newImpl.cache = impl.cache
            }
            
            return newImpl
        }
        
        
        private func decoderForKeyNoThrow<LocalKey: CodingKey>(_ key: LocalKey) -> JSONDecoderImpl {
            let value: JSONValue = getValue(forKey: key) ?? .null
            var newPath = self.codingPath
            newPath.append(key)
            
            return JSONDecoderImpl(
                userInfo: self.impl.userInfo,
                from: value,
                codingPath: newPath,
                options: self.impl.options
            )
        }
        
        @inline(__always) private func getValue<LocalKey: CodingKey>(forKey key: LocalKey) -> JSONValue? {
            guard let value = dictionary[key.stringValue] else { return nil }
            return value
        }
    }
}


extension JSONDecoderImpl.KeyedContainer {
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        try _decodeBoolValue(key: key)
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        try _decodeStringValue(key: key)
    }
    
    func decode(_: Double.Type, forKey key: K) throws -> Double {
        try _decodeFloatingPoint(key: key)
    }
    
    func decode(_: CGFloat.Type, forKey key: K) throws -> CGFloat {
        let value = try decode(Double.self, forKey: key)
        return CGFloat(value)
    }
    
    func decode(_: Float.Type, forKey key: K) throws -> Float {
        try _decodeFloatingPoint(key: key)
    }
    
    func decode(_: Int.Type, forKey key: K) throws -> Int {
        try _decodeFixedWidthInteger(key: key)
    }
    
    func decode(_: Int8.Type, forKey key: K) throws -> Int8 {
        try _decodeFixedWidthInteger(key: key)
    }
    
    func decode(_: Int16.Type, forKey key: K) throws -> Int16 {
        try _decodeFixedWidthInteger(key: key)
    }
    
    func decode(_: Int32.Type, forKey key: K) throws -> Int32 {
        try _decodeFixedWidthInteger(key: key)
    }
    
    func decode(_: Int64.Type, forKey key: K) throws -> Int64 {
        try _decodeFixedWidthInteger(key: key)
    }
    
    func decode(_: UInt.Type, forKey key: K) throws -> UInt {
        try _decodeFixedWidthInteger(key: key)
    }
    
    func decode(_: UInt8.Type, forKey key: K) throws -> UInt8 {
        try _decodeFixedWidthInteger(key: key)
    }
    
    func decode(_: UInt16.Type, forKey key: K) throws -> UInt16 {
        try _decodeFixedWidthInteger(key: key)
    }
    
    func decode(_: UInt32.Type, forKey key: K) throws -> UInt32 {
        try _decodeFixedWidthInteger(key: key)
    }
    
    func decode(_: UInt64.Type, forKey key: K) throws -> UInt64 {
        try _decodeFixedWidthInteger(key: key)
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        try _decodeDecodable(type, forKey: key)
    }
}


extension JSONDecoderImpl.KeyedContainer {
    
    func decodeIfPresent(_ type: Bool.Type, forKey key: K) throws -> Bool? {
        _decodeBoolValueIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? {
        _decodeStringValueIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: Float.Type, forKey key: K) throws -> Float? {
        _decodeFloatingPointIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: CGFloat.Type, forKey key: K) throws -> CGFloat? {
        if let value = try decodeIfPresent(Double.self, forKey: key) {
            return CGFloat(value)
        }
        return nil
    }
    
    func decodeIfPresent(_ type: Double.Type, forKey key: K) throws -> Double? {
        _decodeFloatingPointIfPresent(key: key)
    }
    
    
    func decodeIfPresent(_ type: Int.Type, forKey key: K) throws -> Int? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: Int8.Type, forKey key: K) throws -> Int8? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: Int16.Type, forKey key: K) throws -> Int16? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: Int32.Type, forKey key: K) throws -> Int32? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: Int64.Type, forKey key: K) throws -> Int64? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: UInt.Type, forKey key: K) throws -> UInt? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: UInt8.Type, forKey key: K) throws -> UInt8? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: UInt16.Type, forKey key: K) throws -> UInt16? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: UInt32.Type, forKey key: K) throws -> UInt32? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }
    
    func decodeIfPresent(_ type: UInt64.Type, forKey key: K) throws -> UInt64? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }
    
    func decodeIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? where T: Decodable {
        _decodeDecodableIfPresent(type, forKey: key)
    }
}


extension JSONDecoderImpl.KeyedContainer {
    
    fileprivate func _compatibleDecode<T>(forKey key: Key, logIfKeyMissing: Bool = true, needConvert: Bool = true) -> T? {
        
        guard let value = getValue(forKey: key) else {
            if logIfKeyMissing {
                SmartSentinel.monitorLog(impl: impl, forKey: key, value: nil, type: T.self)
            }
            return impl.cache.initialValueIfPresent(forKey: key, codingPath: codingPath)
        }
        
        SmartSentinel.monitorLog(impl: impl, forKey: key, value: value, type: T.self)
        
        if needConvert {
            if let decoded = Patcher<T>.convertToType(from: value, impl: impl) {
                return decoded
            }
        }
        return impl.cache.initialValueIfPresent(forKey: key, codingPath: codingPath)
    }
    
    
    /// Performs post-mapping cleanup and notifications
    fileprivate func didFinishMapping<T>(_ decodeValue: T) -> T {
        // Properties wrapped by property wrappers don't conform to SmartDecodable protocol.
        // Here we use PostDecodingHookable as an intermediary layer for processing.
        if var value = decodeValue as? SmartDecodable {
            value.didFinishMapping()
            if let temp = value as? T { return temp }
        } else if let value = decodeValue as? PostDecodingHookable {
            if let temp = value.wrappedValueDidFinishMapping() as? T {
                return temp
            }
        }
        return decodeValue
    }
    
    private func decodeWithTransformer<T>(_ transformer: SmartValueTransformer,
                                          type: T.Type,
                                          key: K) -> T? where T: Decodable {
        // 处理属性包装类型
        if let propertyWrapperType = T.self as? any PropertyWrapperInitializable.Type {
            if type is FlatType.Type, let decoded = transformer.tranform(value: impl.json),
               let wrapperValue = propertyWrapperType.createInstance(with: decoded) as? T {
                return didFinishMapping(wrapperValue)
            }
            
            if let value = getValue(forKey: key),
               let decoded = transformer.tranform(value: value),
               let wrapperValue = propertyWrapperType.createInstance(with: decoded) as? T {
                return didFinishMapping(wrapperValue)
            }
        }
        
        // 处理普通类型转换
        if let value = getValue(forKey: key),
           let decoded = transformer.tranform(value: value) as? T {
            return didFinishMapping(decoded)
        }
        return nil
    }
}


extension JSONDecoderImpl.KeyedContainer {
    @inline(__always) private func _decodeFixedWidthIntegerIfPresent<T: FixedWidthInteger>(key: Self.Key) -> T? {
        
        guard let decoded: T = _decodeFixedWidthIntegerIfPresentCore(key: key) else {
            return _compatibleDecode(forKey: key, logIfKeyMissing: false)
        }
        return decoded
    }
    
    @inline(__always) private func _decodeFixedWidthInteger<T: FixedWidthInteger>(key: Self.Key) throws -> T {
        if let decoded: T = _decodeFixedWidthIntegerIfPresentCore(key: key) { return decoded }
        if let value: T = _compatibleDecode(forKey: key, logIfKeyMissing: true) {
            return value
        }
        return try Patcher<T>.defaultForType()
    }
    
    @inline(__always) private func _decodeFixedWidthIntegerIfPresentCore<T: FixedWidthInteger>(key: Self.Key) -> T? {
        guard let value = getValue(forKey: key) else { return nil }
        return impl.unwrapFixedWidthInteger(from: value, for: key, as: T.self)
    }
}


extension JSONDecoderImpl.KeyedContainer {

    @inline(__always) private func _decodeFloatingPointIfPresent<T: LosslessStringConvertible & BinaryFloatingPoint>(key: K) -> T? {
        guard let decoded: T = _decodeFloatingPointIfPresentCore(key: key) else {
            return _compatibleDecode(forKey: key, logIfKeyMissing: false)
        }
        return decoded
    }
    
    @inline(__always) private func _decodeFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>(key: K) throws -> T {
        if let decoded: T = _decodeFloatingPointIfPresentCore(key: key) { return decoded }
        if let value: T = _compatibleDecode(forKey: key, logIfKeyMissing: true) {
            return value
        }
        return try Patcher<T>.defaultForType()
    }
    
    @inline(__always) private func _decodeFloatingPointIfPresentCore<T: LosslessStringConvertible & BinaryFloatingPoint>(key: K) -> T? {
        guard let value = getValue(forKey: key) else { return nil }
        return impl.unwrapFloatingPoint(from: value, for: key, as: T.self)
    }
}


extension JSONDecoderImpl.KeyedContainer {
    @inline(__always) private func _decodeBoolValueIfPresent(key: K) -> Bool? {
        guard let decoded = _decodeBoolValueIfPresentCore(key: key) else {
            return _compatibleDecode(forKey: key, logIfKeyMissing: false)
        }
        return decoded
    }
    
    @inline(__always) private func _decodeBoolValue(key: K) throws -> Bool {
        if let decoded = _decodeBoolValueIfPresentCore(key: key) { return decoded }
        if let value: Bool = _compatibleDecode(forKey: key, logIfKeyMissing: true) {
            return value
        }
        return try Patcher<Bool>.defaultForType()
    }
    
    @inline(__always) private func _decodeBoolValueIfPresentCore(key: K) -> Bool? {
        guard let value = getValue(forKey: key) else { return nil }
        return impl.unwrapBoolValue(from: value, for: key)
    }
}


extension JSONDecoderImpl.KeyedContainer {
    @inline(__always) private func _decodeStringValueIfPresent(key: K) -> String? {
        guard let decoded = _decodeStringValueIfPresentCore(key: key) else {
            return _compatibleDecode(forKey: key, logIfKeyMissing: false)
        }
        return decoded
    }
    
    @inline(__always) private func _decodeStringValue(key: K) throws -> String {
        if let decoded = _decodeStringValueIfPresentCore(key: key) { return decoded }
        if let value: String = _compatibleDecode(forKey: key, logIfKeyMissing: true) {
            return value
        }
        return try Patcher<String>.defaultForType()
    }
    
    @inline(__always) private func _decodeStringValueIfPresentCore(key: K) -> String? {
        guard let value = getValue(forKey: key) else { return nil }
        return impl.unwrapStringValue(from: value, for: key)
    }
}

extension JSONDecoderImpl.KeyedContainer {
    @inline(__always)private func _decodeDecodableIfPresent<T: Decodable>(_ type: T.Type, forKey key: K) -> T? {
        guard let decoded = _decodeDecodableIfPresentCore(type, forKey: key) else {
            if let value: T = _compatibleDecode(forKey: key, logIfKeyMissing: false) {
                return didFinishMapping(value)
            }
            return nil
        }
        return didFinishMapping(decoded)
    }
    
    @inline(__always)private func _decodeDecodable<T: Decodable>(_ type: T.Type, forKey key: K) throws -> T {
        
        guard let decoded = _decodeDecodableIfPresentCore(type, forKey: key) else {
            if let value: T = _compatibleDecode(forKey: key, logIfKeyMissing: true) {
                return didFinishMapping(value)
            }
            let value = try Patcher<T>.defaultForType()
            return didFinishMapping(value)
        }
        return didFinishMapping(decoded)
    }
    
    @inline(__always)private func _decodeDecodableIfPresentCore<T: Decodable>(_ type: T.Type, forKey key: K) -> T? {
        
        // 检查是否有值转换器
        if let transformer = impl.cache.valueTransformer(for: key, codingPath: codingPath) {
            if let decoded = decodeWithTransformer(transformer, type: type, key: key) {
                return decoded
            }
            if let decoded: T = _compatibleDecode(forKey: key, needConvert: false) {
                return decoded
            }
            return nil
        }
        
        /// @SmartFlat的处理
        if let type = type as? FlatType.Type {
            if type.isArray {
                return try? T(from: superDecoder(forKey: key))
            } else {
                return try? T(from: impl)
            }
        }

        guard let newDecoder = try? decoderForKeyCompatibleForJson(key, type: type) else {
            return nil
        }
        
        if let decoded = try? newDecoder.unwrap(as: type) {
            return decoded
        }
        
        return nil
    }
}



/// Handles correspondence between field names that need to be parsed.
fileprivate func _convertDictionary(_ dictionary: [String: JSONValue], impl: JSONDecoderImpl) -> [String: JSONValue] {
    
    var dictionary = dictionary
    
    switch impl.options.keyDecodingStrategy {
    case .useDefaultKeys:
        break
    case .fromSnakeCase:
        // Convert the snake case keys in the container to camel case.
        // If we hit a duplicate key after conversion, then we'll use the first one we saw. Effectively an undefined behavior with JSON dictionaries.
        dictionary = Dictionary(dictionary.map {
            dict in (JSONDecoder.SmartKeyDecodingStrategy._convertFromSnakeCase(dict.key), dict.value)
        }, uniquingKeysWith: { (first, _) in first })
    case .firstLetterLower:
        dictionary = Dictionary(dictionary.map {
            dict in (JSONDecoder.SmartKeyDecodingStrategy._convertFirstLetterToLowercase(dict.key), dict.value)
        }, uniquingKeysWith: { (first, _) in first })
    case .firstLetterUpper:
        dictionary = Dictionary(dictionary.map {
            dict in (JSONDecoder.SmartKeyDecodingStrategy._convertFirstLetterToUppercase(dict.key), dict.value)
        }, uniquingKeysWith: { (first, _) in first })
    }
    
    guard let type = impl.cache.findSnapShot(with: impl.codingPath)?.objectType else { return dictionary }
    
    if let tempValue = KeysMapper.convertFrom(JSONValue.object(dictionary), type: type), let dict = tempValue.object {
        return dict
    }
    return dictionary
}
