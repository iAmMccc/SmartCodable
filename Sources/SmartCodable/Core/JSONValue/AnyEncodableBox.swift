//
//  AnyEncodableBox.swift
//  SmartCodable
//
//  A type-erased bridge for runtime `Any` values.
//

import Foundation

/// Encodes an `Any` value that is only known at runtime.
///
/// Prefers the value's own `Encodable` conformance (Date/Data/URL/plain
/// Codable models). Foundation JSON values such as `NSNumber`, `NSNull`,
/// `[String: Any]` and `[Any]` do not conform to `Encodable`, so they fall
/// back to the library's JSONValue representation instead of being dropped.
struct AnyEncodableBox: Encodable {

    let value: Any

    func encode(to encoder: Encoder) throws {
        if let impl = encoder as? JSONEncoderImpl,
           impl.options.dynamicValueEncodingStrategy == .recursive {
            impl.singleValue = try impl.wrapDynamicValue(value)
        } else if let encodable = value as? Encodable {
            try _encodeOpened(encodable, to: encoder)
        } else if let jsonValue = JSONValue.make(value) {
            try jsonValue.encode(to: encoder)
        } else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

private func _encodeOpened<T: Encodable>(_ value: T, to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
}

extension JSONValue: Encodable {

    func encode(to encoder: Encoder) throws {
        switch self {
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()

        case .bool(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)

        case .string(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)

        case .number(let value):
            var container = encoder.singleValueContainer()
            if let decimal = Decimal(string: value), decimal.isFinite {
                try container.encode(decimal)
            } else if let double = Double(value), double.isFinite {
                try container.encode(double)
            } else {
                throw EncodingError.invalidValue(value, EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "JSON number '\(value)' is not representable."
                ))
            }

        case .array(let values):
            var container = encoder.unkeyedContainer()
            for value in values {
                try container.encode(value)
            }

        case .object(let values):
            var container = encoder.container(keyedBy: _JSONKey.self)
            for (key, value) in values {
                try container.encode(value, forKey: _JSONKey(stringValue: key, intValue: nil))
            }
        }
    }
}

// All runtime collection nodes share one traversal; leaves re-enter the typed
// encoder so Date/Data/URL and model snapshots keep their normal semantics.
extension JSONEncoderImpl {
    func wrapDynamicValue(_ value: Any) throws -> JSONValue {
        if let optional = value as? any _SmartOptionalEncodable {
            guard let wrapped = optional._smartWrappedValue else { return .null }
            return try wrapDynamicValue(wrapped)
        }
        if value is NSNull { return .null }
        if let dictionary = value as? [String: Any] {
            var object: [String: JSONValue] = [:]
            for (key, value) in dictionary {
                let child = getEncoder(for: _JSONKey(stringValue: key, intValue: nil))
                object[key] = try child.wrapDynamicValue(value)
            }
            return .object(object)
        }
        if let array = value as? [Any] {
            return .array(try array.enumerated().map { index, value in
                try getEncoder(for: _JSONKey(index: index)).wrapDynamicValue(value)
            })
        }
        if let encodable = value as? any Encodable { return try wrapUntyped(encodable) }
        if let json = JSONValue.make(value) { return json }
        throw EncodingError.invalidValue(value, .init(
            codingPath: codingPath, debugDescription: "Unsupported runtime value in recursive dynamic encoding."
        ))
    }
}
