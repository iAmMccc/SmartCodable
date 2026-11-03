//
//  EncodingSubjectType.swift
//  SmartCodable
//
//  Resolves the model type that should own an encoding snapshot.
//

import Foundation

/// Internal Optional unwrapping used only to find the wrapped model type.
protocol _SmartOptionalEncodable {
    var _smartWrappedValue: Any? { get }
}

extension Optional: _SmartOptionalEncodable {
    var _smartWrappedValue: Any? {
        switch self {
        case .some(let value):
            return value
        case .none:
            return nil
        }
    }
}

/// Returns the concrete type that owns the model snapshot for an encoding
/// value. Optional/`Optional` chains are unwrapped so `Child?` and
/// `[Child?]` get the same transformer behavior as `Child`.
func encodingSubjectType<E: Encodable>(of value: E, fallback: Any.Type) -> Any.Type {
    var current: Any = value
    var didUnwrap = false

    while let optional = current as? any _SmartOptionalEncodable {
        guard let wrapped = optional._smartWrappedValue else { return fallback }
        didUnwrap = true
        current = wrapped
    }

    return didUnwrap ? type(of: current) : fallback
}
