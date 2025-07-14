//
//  JSONKeyedEncodingContainer.swift
//  SmartCodable
//
//  Created by Mccc on 2024/6/3.
//

import Foundation

struct JSONKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol, _SpecialTreatmentEncoder {
    typealias Key = K

    let impl: JSONEncoderImpl
    let object: JSONFuture.RefObject
    let codingPath: [CodingKey]

    private var firstValueWritten: Bool = false
    var options: SmartJSONEncoder._Options {
        return self.impl.options
    }

    init(impl: JSONEncoderImpl, codingPath: [CodingKey]) {
        self.impl = impl
        self.object = impl.object!
        self.codingPath = codingPath
    }

    // used for nested containers
    init(impl: JSONEncoderImpl, object: JSONFuture.RefObject, codingPath: [CodingKey]) {
        self.impl = impl
        self.object = object
        self.codingPath = codingPath
    }

    mutating func encodeNil(forKey key: Self.Key) throws {
        self.object.set(.null, for: self._converted(key).stringValue)
    }

    mutating func encode(_ value: Bool, forKey key: Self.Key) throws {
        
        let convertedKey = self._converted(key)
        if let jsonValue = impl.cache.tranform(from: value, with: convertedKey, codingPath: codingPath) {
            self.object.set(jsonValue, for: convertedKey.stringValue)
        } else {
            self.object.set(.bool(value), for: self._converted(key).stringValue)
        }
    }

    mutating func encode(_ value: String, forKey key: Self.Key) throws {
        let convertedKey = self._converted(key)
        if let jsonValue = impl.cache.tranform(from: value, with: convertedKey, codingPath: codingPath) {
            self.object.set(jsonValue, for: convertedKey.stringValue)
        } else {
            self.object.set(.string(value), for: convertedKey.stringValue)
        }
    }

    mutating func encode(_ value: Double, forKey key: Self.Key) throws {
        try encodeFloatingPoint(value, key: self._converted(key))
    }

    mutating func encode(_ value: Float, forKey key: Self.Key) throws {
        try encodeFloatingPoint(value, key: self._converted(key))
    }

    mutating func encode(_ value: Int, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: self._converted(key))
    }

    mutating func encode(_ value: Int8, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: self._converted(key))
    }

    mutating func encode(_ value: Int16, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: self._converted(key))
    }

    mutating func encode(_ value: Int32, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: self._converted(key))
    }

    mutating func encode(_ value: Int64, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: self._converted(key))
    }

    mutating func encode(_ value: UInt, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: self._converted(key))
    }

    mutating func encode(_ value: UInt8, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: self._converted(key))
    }

    mutating func encode(_ value: UInt16, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: self._converted(key))
    }

    mutating func encode(_ value: UInt32, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: self._converted(key))
    }

    mutating func encode(_ value: UInt64, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: self._converted(key))
    }

    mutating func encode<T>(_ value: T, forKey key: Self.Key) throws where T: Encodable {
        let convertedKey = self._converted(key)
        if let jsonValue = impl.cache.tranform(from: value, with: convertedKey, codingPath: codingPath) {
            self.object.set(jsonValue, for: convertedKey.stringValue)
        } else {
            if let encoded = try self.wrapEncodable(value, for: convertedKey) {
                self.object.set(encoded, for: convertedKey.stringValue)
            }
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: Self.Key) ->
        KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey
    {
        let convertedKey = self._converted(key)
        let newPath = self.codingPath + [convertedKey]
        let object = self.object.setObject(for: convertedKey.stringValue)
        let nestedContainer = JSONKeyedEncodingContainer<NestedKey>(impl: impl, object: object, codingPath: newPath)
        return KeyedEncodingContainer(nestedContainer)
    }

    mutating func nestedUnkeyedContainer(forKey key: Self.Key) -> UnkeyedEncodingContainer {
        let convertedKey = self._converted(key)
        let newPath = self.codingPath + [convertedKey]
        let array = self.object.setArray(for: convertedKey.stringValue)
        let nestedContainer = JSONUnkeyedEncodingContainer(impl: impl, array: array, codingPath: newPath)
        return nestedContainer
    }

    mutating func superEncoder() -> Encoder {
        let newEncoder = self.getEncoder(for: _JSONKey.super)
        self.object.set(newEncoder, for: _JSONKey.super.stringValue)
        return newEncoder
    }

    mutating func superEncoder(forKey key: Self.Key) -> Encoder {
        let convertedKey = self._converted(key)
        let newEncoder = self.getEncoder(for: convertedKey)
        self.object.set(newEncoder, for: convertedKey.stringValue)
        return newEncoder
    }
}

extension JSONKeyedEncodingContainer {
    @inline(__always) private mutating func encodeFloatingPoint<F: FloatingPoint & CustomStringConvertible>(_ float: F, key: CodingKey) throws {
        
        if let jsonValue = impl.cache.tranform(from: float, with: key, codingPath: codingPath) {
            self.object.set(jsonValue, for: key.stringValue)
        } else {
            let value = try self.wrapFloat(float, for: key)
            self.object.set(value, for: key.stringValue)
        }
    }

    @inline(__always) private mutating func encodeFixedWidthInteger<N: FixedWidthInteger>(_ value: N, key: CodingKey) throws {
        
        if let jsonValue = impl.cache.tranform(from: value, with: key, codingPath: codingPath) {
            self.object.set(jsonValue, for: key.stringValue)
        } else {
            self.object.set(.number(value.description), for: key.stringValue)
        }
    }
}
