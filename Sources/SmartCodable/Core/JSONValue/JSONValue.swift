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
    
    
    static func make(_ value: Any) -> Self? {
        if let jsonValue = value as? JSONValue {
            return jsonValue
        }
        
        switch value {
        case is NSNull:
            return .null
        case let string as String:
            return .string(string)
        case let number as NSNumber:
            return .number(number.stringValue)
        case let bool as Bool:
            return .bool(bool)
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
            // 这里判断 string 是否能转成 Int 或 Double
            if let intValue = Int(n) {
                return intValue
            } else if let doubleValue = Double(n) {
                return doubleValue
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
    
    static func from(_ any: Any) throws -> JSONValue {
        switch any {
        case let dict as [String: Any]:
            let object = try dict.reduce(into: [String: JSONValue]()) { result, pair in
                result[pair.key] = try from(pair.value)
            }
            return .object(object)

        case let array as [Any]:
            let arr = try array.map { try from($0) }
            return .array(arr)

        case let str as String:
            return .string(str)

        case let num as NSNumber:
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                return .bool(num.boolValue)
            } else {
                return .number(num.stringValue)
            }

        case is NSNull:
            return .null

        default:
            throw DecodingError.dataCorrupted(
                .init(codingPath: [],
                      debugDescription: "Unsupported value: \(type(of: any))")
            )
        }
    }
}

fileprivate func _toData(_ value: Any) -> Data? {
    guard JSONSerialization.isValidJSONObject(value) else { return nil }
    return try? JSONSerialization.data(withJSONObject: value)
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

private extension JSONValue {
    func toObjcRepresentation(options: JSONSerialization.ReadingOptions) throws -> Any {
        switch self {
        case .array(let values):
            let array = try values.map { try $0.toObjcRepresentation(options: options) }
            if !options.contains(.mutableContainers) {
                return array
            }
            return NSMutableArray(array: array, copyItems: false)
        case .object(let object):
            let dictionary = try object.mapValues { try $0.toObjcRepresentation(options: options) }
            if !options.contains(.mutableContainers) {
                return dictionary
            }
            return NSMutableDictionary(dictionary: dictionary, copyItems: false)
        case .bool(let bool):
            return NSNumber(value: bool)
        case .number(let string):
            guard let number = NSNumber.fromJSONNumber(string) else {
                throw JSONError.numberIsNotRepresentableInSwift(parsed: string)
            }
            return number
        case .null:
            return NSNull()
        case .string(let string):
            if options.contains(.mutableLeaves) {
                return NSMutableString(string: string)
            }
            return string
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
}
enum JSONError: Swift.Error, Equatable {
    case cannotConvertInputDataToUTF8
    case unexpectedCharacter(ascii: UInt8, characterIndex: Int)
    case unexpectedEndOfFile
    case tooManyNestedArraysOrDictionaries(characterIndex: Int)
    case invalidHexDigitSequence(String, index: Int)
    case unexpectedEscapedCharacter(ascii: UInt8, in: String, index: Int)
    case unescapedControlCharacterInString(ascii: UInt8, in: String, index: Int)
    case expectedLowSurrogateUTF8SequenceAfterHighSurrogate(in: String, index: Int)
    case couldNotCreateUnicodeScalarFromUInt32(in: String, index: Int, unicodeScalarValue: UInt32)
    case numberWithLeadingZero(index: Int)
    case numberIsNotRepresentableInSwift(parsed: String)
    case singleFragmentFoundButNotAllowed
    case invalidUTF8Sequence(Data, characterIndex: Int)
}



// for encdoe
extension JSONValue {

    internal struct Writer {
        let options: SmartJSONEncoder.OutputFormatting

        init(options: SmartJSONEncoder.OutputFormatting) {
            self.options = options
        }

        func writeValue(_ value: JSONValue) -> [UInt8] {
            var bytes = [UInt8]()
            if self.options.contains(.prettyPrinted) {
                self.writeValuePretty(value, into: &bytes)
            }
            else {
                self.writeValue(value, into: &bytes)
            }
            return bytes
        }

        private func writeValue(_ value: JSONValue, into bytes: inout [UInt8]) {
            switch value {
            case .null:
                bytes.append(contentsOf: [UInt8]._null)
            case .bool(true):
                bytes.append(contentsOf: [UInt8]._true)
            case .bool(false):
                bytes.append(contentsOf: [UInt8]._false)
            case .string(let string):
                self.encodeString(string, to: &bytes)
            case .number(let string):
                bytes.append(contentsOf: string.utf8)
            case .array(let array):
                var iterator = array.makeIterator()
                bytes.append(._openbracket)
                // we don't like branching, this is why we have this extra
                if let first = iterator.next() {
                    self.writeValue(first, into: &bytes)
                }
                while let item = iterator.next() {
                    bytes.append(._comma)
                    self.writeValue(item, into:&bytes)
                }
                bytes.append(._closebracket)
            case .object(let dict):
                if #available(macOS 10.13, *), options.contains(.sortedKeys) {
                    let sorted = dict.sorted { $0.key.compare($1.key, options: [.caseInsensitive, .diacriticInsensitive, .forcedOrdering, .numeric, .widthInsensitive]) == .orderedAscending }
                    self.writeObject(sorted, into: &bytes)
                } else {
                    self.writeObject(dict, into: &bytes)
                }
            }
        }

        private func writeObject<Object: Sequence>(_ object: Object, into bytes: inout [UInt8], depth: Int = 0)
            where Object.Element == (key: String, value: JSONValue)
        {
            var iterator = object.makeIterator()
            bytes.append(._openbrace)
            if let (key, value) = iterator.next() {
                self.encodeString(key, to: &bytes)
                bytes.append(._colon)
                self.writeValue(value, into: &bytes)
            }
            while let (key, value) = iterator.next() {
                bytes.append(._comma)
                // key
                self.encodeString(key, to: &bytes)
                bytes.append(._colon)

                self.writeValue(value, into: &bytes)
            }
            bytes.append(._closebrace)
        }

        private func addInset(to bytes: inout [UInt8], depth: Int) {
            bytes.append(contentsOf: [UInt8](repeating: ._space, count: depth * 2))
        }

        private func writeValuePretty(_ value: JSONValue, into bytes: inout [UInt8], depth: Int = 0) {
            switch value {
            case .null:
                bytes.append(contentsOf: [UInt8]._null)
            case .bool(true):
                bytes.append(contentsOf: [UInt8]._true)
            case .bool(false):
                bytes.append(contentsOf: [UInt8]._false)
            case .string(let string):
                self.encodeString(string, to: &bytes)
            case .number(let string):
                bytes.append(contentsOf: string.utf8)
            case .array(let array):
                var iterator = array.makeIterator()
                bytes.append(contentsOf: [._openbracket, ._newline])
                if let first = iterator.next() {
                    self.addInset(to: &bytes, depth: depth + 1)
                    self.writeValuePretty(first, into: &bytes, depth: depth + 1)
                }
                while let item = iterator.next() {
                    bytes.append(contentsOf: [._comma, ._newline])
                    self.addInset(to: &bytes, depth: depth + 1)
                    self.writeValuePretty(item, into: &bytes, depth: depth + 1)
                }
                bytes.append(._newline)
                self.addInset(to: &bytes, depth: depth)
                bytes.append(._closebracket)
            case .object(let dict):
                if #available(macOS 10.13, *), options.contains(.sortedKeys) {
                    let sorted = dict.sorted { $0.key.compare($1.key, options: [.caseInsensitive, .diacriticInsensitive, .forcedOrdering, .numeric, .widthInsensitive]) == .orderedAscending }
                    self.writePrettyObject(sorted, into: &bytes, depth: depth)
                } else {
                    self.writePrettyObject(dict, into: &bytes, depth: depth)
                }
            }
        }

        private func writePrettyObject<Object: Sequence>(_ object: Object, into bytes: inout [UInt8], depth: Int = 0)
            where Object.Element == (key: String, value: JSONValue)
        {
            var iterator = object.makeIterator()
            bytes.append(contentsOf: [._openbrace, ._newline])
            if let (key, value) = iterator.next() {
                self.addInset(to: &bytes, depth: depth + 1)
                self.encodeString(key, to: &bytes)
                bytes.append(contentsOf: [._space, ._colon, ._space])
                self.writeValuePretty(value, into: &bytes, depth: depth + 1)
            }
            while let (key, value) = iterator.next() {
                bytes.append(contentsOf: [._comma, ._newline])
                self.addInset(to: &bytes, depth: depth + 1)
                // key
                self.encodeString(key, to: &bytes)
                bytes.append(contentsOf: [._space, ._colon, ._space])
                // value
                self.writeValuePretty(value, into: &bytes, depth: depth + 1)
            }
            bytes.append(._newline)
            self.addInset(to: &bytes, depth: depth)
            bytes.append(._closebrace)
        }

        private func encodeString(_ string: String, to bytes: inout [UInt8]) {
            bytes.append(UInt8(ascii: "\""))
            let stringBytes = string.utf8
            var startCopyIndex = stringBytes.startIndex
            var nextIndex = startCopyIndex

            while nextIndex != stringBytes.endIndex {
                switch stringBytes[nextIndex] {
                case 0 ..< 32, UInt8(ascii: "\""), UInt8(ascii: "\\"):
                    // All Unicode characters may be placed within the
                    // quotation marks, except for the characters that MUST be escaped:
                    // quotation mark, reverse solidus, and the control characters (U+0000
                    // through U+001F).
                    // https://tools.ietf.org/html/rfc8259#section-7

                    // copy the current range over
                    bytes.append(contentsOf: stringBytes[startCopyIndex ..< nextIndex])
                    switch stringBytes[nextIndex] {
                    case UInt8(ascii: "\""): // quotation mark
                        bytes.append(contentsOf: [._backslash, ._quote])
                    case UInt8(ascii: "\\"): // reverse solidus
                        bytes.append(contentsOf: [._backslash, ._backslash])
                    case 0x08: // backspace
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "b")])
                    case 0x0C: // form feed
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "f")])
                    case 0x0A: // line feed
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "n")])
                    case 0x0D: // carriage return
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "r")])
                    case 0x09: // tab
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "t")])
                    default:
                        func valueToAscii(_ value: UInt8) -> UInt8 {
                            switch value {
                            case 0 ... 9:
                                return value + UInt8(ascii: "0")
                            case 10 ... 15:
                                return value - 10 + UInt8(ascii: "a")
                            default:
                                preconditionFailure()
                            }
                        }
                        bytes.append(UInt8(ascii: "\\"))
                        bytes.append(UInt8(ascii: "u"))
                        bytes.append(UInt8(ascii: "0"))
                        bytes.append(UInt8(ascii: "0"))
                        let first = stringBytes[nextIndex] / 16
                        let remaining = stringBytes[nextIndex] % 16
                        bytes.append(valueToAscii(first))
                        bytes.append(valueToAscii(remaining))
                    }

                    nextIndex = stringBytes.index(after: nextIndex)
                    startCopyIndex = nextIndex
                case UInt8(ascii: "/"):
                    if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *), options.contains(.withoutEscapingSlashes) == false {
                        bytes.append(contentsOf: stringBytes[startCopyIndex ..< nextIndex])
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "/")])
                        nextIndex = stringBytes.index(after: nextIndex)
                        startCopyIndex = nextIndex
                    } else {
                        bytes.append(contentsOf: stringBytes[startCopyIndex ..< nextIndex])
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "/")])
                        nextIndex = stringBytes.index(after: nextIndex)
                        startCopyIndex = nextIndex
                    }
                    
                default:
                    nextIndex = stringBytes.index(after: nextIndex)
                }
            }

            // copy everything, that hasn't been copied yet
            bytes.append(contentsOf: stringBytes[startCopyIndex ..< nextIndex])
            bytes.append(UInt8(ascii: "\""))
        }
    }
}

