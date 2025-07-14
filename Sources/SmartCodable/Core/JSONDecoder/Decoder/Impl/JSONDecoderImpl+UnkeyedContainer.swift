//
//  JSONDecoderImpl+UnkeyedContainer.swift
//  SmartCodable
//
//  Created by Mccc on 2024/5/17.
//

import Foundation
extension JSONDecoderImpl {
    struct UnkeyedContainer: UnkeyedDecodingContainer {
        let impl: JSONDecoderImpl
        let codingPath: [CodingKey]
        let array: [JSONValue]

        var count: Int? { self.array.count }
        var isAtEnd: Bool { self.currentIndex >= (self.count ?? 0) }
        var currentIndex = 0

        init(impl: JSONDecoderImpl, codingPath: [CodingKey], array: [JSONValue]) {
            self.impl = impl
            self.codingPath = codingPath
            self.array = array
        }

        mutating func decodeNil() throws -> Bool {
            if try self.getNextValue(ofType: Never.self) == .null {
                self.currentIndex += 1
                return true
            }

            // The protocol states:
            //   If the value is not null, does not increment currentIndex.
            return false
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws
            -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey
        {
            let decoder = decoderForNextElement(ofType: KeyedDecodingContainer<NestedKey>.self)
            let container = try decoder.container(keyedBy: type)

            self.currentIndex += 1
            return container
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            let decoder = decoderForNextElement(ofType: UnkeyedDecodingContainer.self)
            let container = try decoder.unkeyedContainer()

            self.currentIndex += 1
            return container
        }

        mutating func superDecoder() throws -> Decoder {
            let decoder = decoderForNextElement(ofType: Decoder.self)
            self.currentIndex += 1
            return decoder
        }

        private mutating func decoderForNextElement<T>(ofType: T.Type) -> JSONDecoderImpl {
            var value: JSONValue
            do {
                value = try getNextValue(ofType: T.self)
            } catch {
                value = JSONValue.array([])
            }
            
            let newPath = self.codingPath + [_JSONKey(index: self.currentIndex)]
            
            return JSONDecoderImpl(
                userInfo: self.impl.userInfo,
                from: value,
                codingPath: newPath,
                options: self.impl.options
            )
        }
    }
}


// Because UnkeyedDecodingContainer itself is not directly associated with a particular model property,
// but is used to parse unlabeled sequences,
// it does not automatically select a decoding method for a particular type.
// Instead, it tries to use generic decoding methods so that it can handle values of various types.
// Specific types of decode methods, the use of scenarios are relatively few,
// `let first = try unkeyedContainer.decode(Int.self) '.
extension JSONDecoderImpl.UnkeyedContainer {
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard let value = try? self.getNextValue(ofType: Bool.self) else {
            return try forceDecode()
        }
        guard case .bool(let bool) = value else {
            return try forceDecode()
        }
        self.currentIndex += 1
        return bool
    }

    mutating func decode(_ type: String.Type) throws -> String {
        guard let value = try? self.getNextValue(ofType: Bool.self) else {
            return try forceDecode()
        }
        guard case .string(let string) = value else {
            return try forceDecode()
        }
        self.currentIndex += 1
        return string
    }

    mutating func decode(_: Double.Type) throws -> Double {
        try decodeFloatingPoint()
    }

    mutating func decode(_: Float.Type) throws -> Float {
        try decodeFloatingPoint()
    }

    mutating func decode(_: Int.Type) throws -> Int {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: Int8.Type) throws -> Int8 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: Int16.Type) throws -> Int16 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: Int32.Type) throws -> Int32 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: Int64.Type) throws -> Int64 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: UInt.Type) throws -> UInt {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: UInt8.Type) throws -> UInt8 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: UInt16.Type) throws -> UInt16 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: UInt32.Type) throws -> UInt32 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: UInt64.Type) throws -> UInt64 {
        try decodeFixedWidthInteger()
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        
        // If it is a basic data type,
        // a new decoder is still created for parsing.
        // If type is of type Int, then SingleContainer is created.
        let newDecoder = decoderForNextElement(ofType: type)
        
        // Because of the requirement that the index not be incremented unless
        // decoding the desired result type succeeds, it can not be a tail call.
        // Hopefully the compiler still optimizes well enough that the result
        // doesn't get copied around.
        if codingPath.isEmpty {
            guard let result = try? newDecoder.unwrap(as: type) else {
                let decoded: T = try forceDecode()
                return didFinishMapping(decoded)
            }
            self.currentIndex += 1
            return didFinishMapping(result)
        } else {
            // If it is not the first level of array model parsing, it is not compatible.
            // Throw an exception to make keyedController compatible.
            let result = try newDecoder.unwrap(as: type)
            self.currentIndex += 1
            return didFinishMapping(result)
        }
    }
    
    @inline(__always) private mutating func decodeFixedWidthInteger<T: FixedWidthInteger>() throws -> T {
        guard let value = try? self.getNextValue(ofType: T.self) else {
            return try forceDecode()
        }
        
        let key = _JSONKey(index: self.currentIndex)
        guard let result = self.impl.unwrapFixedWidthInteger(from: value, for: key, as: T.self) else {
            return try forceDecode()
        }
        self.currentIndex += 1
        return result
    }
    @inline(__always) private mutating func decodeFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() throws -> T {
        guard let value = try? self.getNextValue(ofType: T.self) else {
            return try forceDecode()
        }
        
        let key = _JSONKey(index: self.currentIndex)
        guard let result = self.impl.unwrapFloatingPoint(from: value, for: key, as: T.self) else {
            return try forceDecode()
        }
        self.currentIndex += 1
        return result
    }
    
    
    fileprivate mutating func forceDecode<T>() throws -> T {
        
        let key = _JSONKey(index: currentIndex)

        guard let value = try? self.getNextValue(ofType: T.self) else {
            let decoded: T = try impl.cache.initialValue(forKey: key, codingPath: codingPath)
            SmartSentinel.monitorLog(impl: impl, forKey: key, value: nil, type: T.self)
            self.currentIndex += 1
            return decoded
        }
        
        SmartSentinel.monitorLog(impl: impl, forKey: key, value: value, type: T.self)

        
        if let decoded = Patcher<T>.convertToType(from: value, impl: impl) {
            self.currentIndex += 1
            return decoded
        } else {
            let decoded: T = try impl.cache.initialValue(forKey: key, codingPath: codingPath)
            self.currentIndex += 1
            return decoded
        }
    }
}

extension JSONDecoderImpl.UnkeyedContainer {

    mutating func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
        guard let value = try? self.getNextValue(ofType: Bool.self) else {
            return optionalDecode()
        }
        guard case .bool(let bool) = value else {
            return optionalDecode()
        }
        self.currentIndex += 1
        return bool
    }

    
    mutating func decodeIfPresent(_ type: String.Type) throws -> String? {
        self.currentIndex += 1
        guard let value = try? self.getNextValue(ofType: String.self) else {
            return optionalDecode()
        }
        guard case .string(let string) = value else {
            return optionalDecode()
        }
        self.currentIndex += 1
        return string
    }
    
    mutating func decodeIfPresent(_ type: Double.Type) throws -> Double? {
        return decodeIfPresentFloatingPoint()
    }
    
    mutating func decodeIfPresent(_ type: Float.Type) throws -> Float? {
        return decodeIfPresentFloatingPoint()
    }
    
    mutating func decodeIfPresent(_ type: Int.Type) throws -> Int? {
        return decodeIfPresentFixedWidthInteger()
    }
    
    mutating func decodeIfPresent(_ type: Int8.Type) throws -> Int8? {
        return decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: Int16.Type) throws -> Int16? {
        return decodeIfPresentFixedWidthInteger()
    }
    
    mutating func decodeIfPresent(_ type: Int32.Type) throws -> Int32? {
        return decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: Int64.Type) throws -> Int64? {
        return decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: UInt.Type) throws -> UInt? {
        return decodeIfPresentFixedWidthInteger()
    }
    
    mutating func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8? {
        return decodeIfPresentFixedWidthInteger()
    }
    
    mutating func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16? {
        return decodeIfPresentFixedWidthInteger()
    }
    
    mutating func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32? {
        return decodeIfPresentFixedWidthInteger()
    }
    
    mutating func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64? {
        return decodeIfPresentFixedWidthInteger()
    }

    ///   is not convertible to the requested type.
    mutating func decodeIfPresent<T>(_ type: T.Type) throws -> T? where T : Decodable {
        let newDecoder = decoderForNextElement(ofType: type)
        if let decoded = try? newDecoder.unwrap(as: type) {
            self.currentIndex += 1
            return didFinishMapping(decoded)
        } else if let decoded: T = optionalDecode() {
            self.currentIndex += 1
            return didFinishMapping(decoded)
        } else {
            self.currentIndex += 1
            return nil
        }
    }
    
    @inline(__always) private mutating func decodeIfPresentFixedWidthInteger<T: FixedWidthInteger>() -> T? {
        guard let value = try? self.getNextValue(ofType: T.self) else {
            return optionalDecode()
        }
        
        let key = _JSONKey(index: self.currentIndex)
        guard let result = self.impl.unwrapFixedWidthInteger(from: value, for: key, as: T.self) else {
            return optionalDecode()
        }
        self.currentIndex += 1
        return result
    }
    @inline(__always) private mutating func decodeIfPresentFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() -> T?  {
        guard let value = try? self.getNextValue(ofType: T.self) else {
            return optionalDecode()
        }
        
        let key = _JSONKey(index: self.currentIndex)
        guard let result = self.impl.unwrapFloatingPoint(from: value, for: key, as: T.self) else {
            return optionalDecode()
        }
        self.currentIndex += 1
        return result
    }
    
    fileprivate mutating func optionalDecode<T>() -> T? {
        guard let value = try? self.getNextValue(ofType: T.self) else {
            self.currentIndex += 1
            return nil
        }
        let key = _JSONKey(index: self.currentIndex)
        SmartSentinel.monitorLog(impl: impl, forKey: key, value: value, type: T.self)
        if let decoded = Patcher<T>.convertToType(from: value, impl: impl) {
            self.currentIndex += 1
            return decoded
        } else {
            self.currentIndex += 1
            return nil
        }
    }
}


extension JSONDecoderImpl.UnkeyedContainer {
    // 被属性包装器包裹的，不会调用该方法。Swift的类型系统在运行时无法直接识别出wrappedValue的实际类型.
    fileprivate func didFinishMapping<T>(_ decodeValue: T) -> T {
        
        // 减少动态派发开销，is 检查是编译时静态行为，比 as? 动态转换更高效。
        guard T.self is SmartDecodable.Type else { return decodeValue }
        
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
}


extension JSONDecoderImpl.UnkeyedContainer {
    @inline(__always)
    private func getNextValue<T>(ofType: T.Type) throws -> JSONValue {
        guard !self.isAtEnd else {
            var message = "Unkeyed container is at end."
            
            if T.self == JSONDecoderImpl.UnkeyedContainer.self {
                message = "Cannot get nested unkeyed container -- unkeyed container is at end."
            }
            if T.self == Decoder.self {
                message = "Cannot get superDecoder() -- unkeyed container is at end."
            }

            var path = self.codingPath
            path.append(_JSONKey(index: self.currentIndex))

            throw DecodingError.valueNotFound(
                T.self,
                .init(codingPath: path,
                      debugDescription: message,
                      underlyingError: nil))
        }
        return self.array[self.currentIndex]
    }
}
