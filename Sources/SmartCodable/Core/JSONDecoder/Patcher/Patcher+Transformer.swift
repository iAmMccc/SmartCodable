//
//  TypePatcher.swift
//  SmartCodable
//
//  Created by Mccc on 2023/9/5.
//

import Foundation

extension Patcher {
    struct Transformer {
        static func typeTransform(from jsonValue: JSONValue, impl: JSONDecoderImpl) -> T? {
            return (T.self as? TypeTransformable.Type)?.transformValue(from: jsonValue, impl: impl) as? T
        }
    }
}


protocol TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Self?
}


extension Bool: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Bool? {
        
        switch value {
        case .bool(let bool):
            return bool
        case .string(let string):
            if ["1","YES","Yes","yes","TRUE","True","true"].contains(string) { return true }
            if ["0","NO","No","no","FALSE","False","false"].contains(string) { return false }
        case .number(_):
            if let int = impl.unwrapFixedWidthInteger(from: value, as: Int.self) {
                if int == 1 {
                    return true
                } else if int == 0 {
                    return false
                }
            }
        default:
            break
        }
        return nil
    }
}


extension String: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> String? {
        switch value {
        case .string(let string):
            return string
        case .number(let number):
            if let int = impl.unwrapFixedWidthInteger(from: value, as: Int.self) {
                return "\(int)"
            } else if let double = impl.unwrapFloatingPoint(from: value, as: Double.self) {
                return "\(double)"
            }
            return number
        default:
            break
        }
        return nil
    }
}


extension Int: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Int? {
        return _fixedWidthInteger(from: value)
    }
}

extension Int8: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Int8? {
        return _fixedWidthInteger(from: value)
    }
}

extension Int16: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Int16? {
        return _fixedWidthInteger(from: value)
    }
}


extension Int32: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Int32? {
        return _fixedWidthInteger(from: value)
    }
}

extension Int64: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Int64? {
        return _fixedWidthInteger(from: value)
    }
}

extension UInt: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> UInt? {
        return _fixedWidthInteger(from: value)
    }
}

extension UInt8: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> UInt8? {
        return _fixedWidthInteger(from: value)
    }
}

extension UInt16: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> UInt16? {
        return _fixedWidthInteger(from: value)
    }
}


extension UInt32: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> UInt32? {
        return _fixedWidthInteger(from: value)
    }
}

extension UInt64: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> UInt64? {
        return _fixedWidthInteger(from: value)
    }
}


extension Float: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Float? {
        impl.unwrapFloatingPoint(from: value, as: Float.self)
    }
}


extension Double: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Double? {
        impl.unwrapFloatingPoint(from: value, as: Double.self)
    }
}


extension CGFloat: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> CGFloat? {
        impl.unwrapFloatingPoint(from: value, as: Double.self).map { CGFloat($0) }
    }
}


private func _fixedWidthInteger<T: FixedWidthInteger>(from value: JSONValue) -> T? {
    let text: String
    switch value {
    case .string(let string), .number(let string):
        text = string
    default:
        return nil
    }

    // Keep exact integer parsing as the fast path, including Int64/UInt64 edges.
    if let integer = T(text) { return integer }
    guard let parts = _DecimalParts(text, maxDigits: max(
        String(describing: T.min).utf8.count,
        String(describing: T.max).utf8.count
    )) else { return nil }
    return _decimalInteger(parts, as: T.self)
}

/// Preserve the decimal digits and exponent until range checking is complete.
/// Converting this text to Double first can turn an out-of-range value into
/// Int64.min or Int64.max before `T(exactly:)` sees it.
private struct _DecimalParts {
    let negative: Bool
    let digits: [UInt8]
    let scale: Int
    let maxDigits: Int

    init?(_ text: String, maxDigits: Int) {
        let bytes = Array(text.utf8)
        guard !bytes.isEmpty else { return nil }
        var index = 0
        let negative = bytes[index] == 45
        if negative || bytes[index] == 43 { index += 1 }

        var digits: [UInt8] = []
        var fractionalDigits = 0
        var hasPoint = false
        while index < bytes.count {
            let byte = bytes[index]
            if byte == 46, !hasPoint {
                hasPoint = true
            } else if byte >= 48, byte <= 57 {
                digits.append(byte)
                if hasPoint { fractionalDigits += 1 }
            } else {
                break
            }
            index += 1
        }
        guard !digits.isEmpty else { return nil }

        var exponent = 0
        var exponentNegative = false
        if index < bytes.count, bytes[index] == 101 || bytes[index] == 69 {
            index += 1
            if index < bytes.count, bytes[index] == 43 || bytes[index] == 45 {
                exponentNegative = bytes[index] == 45
                index += 1
            }
            guard index < bytes.count else { return nil }
            let limit = digits.count + maxDigits + 1
            var sawExponentDigit = false
            while index < bytes.count, bytes[index] >= 48, bytes[index] <= 57 {
                let digit = Int(bytes[index] - 48)
                if exponent < limit {
                    exponent = exponent > (limit - digit) / 10 ? limit : min(limit, exponent * 10 + digit)
                }
                index += 1
                sawExponentDigit = true
            }
            guard sawExponentDigit else { return nil }
        }
        guard index == bytes.count else { return nil }

        self.negative = negative
        self.digits = digits
        self.scale = (exponentNegative ? -exponent : exponent) - fractionalDigits
        self.maxDigits = maxDigits
    }
}

private func _decimalInteger<T: FixedWidthInteger>(_ parts: _DecimalParts, as type: T.Type) -> T? {
    if parts.digits.allSatisfy({ $0 == 48 }) { return 0 }

    let wholeCount = parts.scale >= 0
        ? parts.digits.count
        : max(0, parts.digits.count + parts.scale)
    let fraction = parts.digits.dropFirst(wholeCount)
    let strategy = SmartCodableOptions.numberStrategy
    if strategy == .strict, fraction.contains(where: { $0 != 48 }) { return nil }

    var whole = Array(parts.digits.prefix(wholeCount).drop(while: { $0 == 48 }))
    let trailingZeros = max(0, parts.scale)
    guard whole.count + trailingZeros <= parts.maxDigits else { return nil }
    whole.append(contentsOf: repeatElement(UInt8(48), count: trailingZeros))
    if whole.isEmpty { whole = [48] }

    // If the exponent moved every digit past the first fractional place,
    // leading fractional zeroes prevent rounding up even for a leading 9.
    let hasLeadingFractionalZero = parts.scale < 0 && -parts.scale > parts.digits.count
    if strategy == .rounded, !hasLeadingFractionalZero,
       let firstFractionDigit = fraction.first, firstFractionDigit >= 53 {
        var position = whole.count
        while position > 0 {
            position -= 1
            if whole[position] < 57 {
                whole[position] += 1
                break
            }
            whole[position] = 48
            if position == 0 { whole.insert(49, at: 0) }
        }
    }
    guard whole.count <= parts.maxDigits else { return nil }
    let magnitude = String(decoding: whole, as: UTF8.self)
    let signed = parts.negative && magnitude != "0" ? "-" + magnitude : magnitude
    return T(signed)
}
