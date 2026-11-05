//
//  SmartCoding.swift
//  BTCodable
//
//  Created by Mccc on 2023/8/1.
//

import Foundation

/// Global coding/decoding configuration namespace for SmartCodable
public struct SmartCodableOptions {

    private static let lock = NSLock()

    private static var _numberStrategy: NumberConversionStrategy = .strict
    private static var _ignoreNull: Bool = true
    private static var _compactElementStrategy: CompactElementStrategy = .legacy

    /// Number conversion strategy during decoding (default: .strict)
    ///
    /// - Description: Controls how to handle precision loss when converting JSON numbers (e.g., floating-point) to target types (e.g., integer)
    /// - Examples:
    ///   - Converting JSON's 3.14 to Int:
    ///     - .strict:   Returns nil (no precision loss allowed)
    ///     - .truncate: Returns 3 (direct truncation)
    ///     - .rounded:  Returns 3 (rounds to nearest)
    ///
    /// - Note: This only affects decoding process
    public static var numberStrategy: NumberConversionStrategy {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _numberStrategy
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _numberStrategy = newValue
        }
    }


    /// Whether to treat JSON `null` as a decoded value for `Any`-typed property wrappers (default: `true`)
    ///
    /// 在对使用 `Any`（或 Any 支持的属性包装器）进行解码时，决定是否把 JSON 中的 `null` 当作可被解码并赋值到 `Any` 的值。
    ///
    /// - Behavior:
    ///   - 当为 `true`（默认）时：遇到 JSON 字段值为 `null`，属性包装器**不会**把 `NSNull`/`nil` 赋给目标 `Any`，而是跳过赋值（保持属性的默认值或原有值）。
    ///   - 当为 `false` 时：遇到 JSON 字段值为 `null`，属性包装器会把 `NSNull()`（或解码为 `nil`，取决于你的实现）作为解析结果赋给 `Any`，从而能在运行时检测到该字段为 `null`。
    public static var ignoreNull: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _ignoreNull
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _ignoreNull = newValue
        }
    }

    /// Element decoding strategy for `@SmartCompact.Array` (default: `.legacy`)
    ///
    /// - `.legacy`: keeps the 7.0.1 acceptance domain. The raw JSON value is bridged and cast to the
    ///   element type, so `"2"` is not converted to `2`, `"YES"` is not converted to `true`, and
    ///   `3.5` is not truncated to `3`. `SmartCodableX` models and `Optional` elements keep their
    ///   existing behavior.
    /// - `.convert`: converts the raw JSON value into the declared element type (`"2"` → `2`,
    ///   `"YES"` → `true`) and decodes ordinary `Codable` elements such as plain structs.
    ///
    /// - Note: This affects both decoding and encoding of `@SmartCompact.Array` elements, and never
    ///   changes ordinary (non-compact) arrays.
    public static var compactElementStrategy: CompactElementStrategy {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _compactElementStrategy
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _compactElementStrategy = newValue
        }
    }
}


extension SmartCodableOptions {
    /// Numeric type conversion strategy
    public enum NumberConversionStrategy {
        /// Strict mode: Must match exactly, otherwise returns nil (default)
        ///
        /// - Decoding example: Double(3.14) → Int? returns nil
        case strict
        
        /// Directly truncates decimal portion (e.g., 3.99 → 3)
        ///
        /// - Decoding example: Double(3.99) → Int returns 3
        case truncate
        
        /// Rounds to nearest integer (e.g., 3.5 → 4, 3.4 → 3)
        ///
        /// - Decoding example: Double(3.6) → Int returns 4
        case rounded
    }
}


extension SmartCodableOptions {
    /// Element decoding strategy for `@SmartCompact.Array`
    public enum CompactElementStrategy {
        /// Bridge the raw JSON value and cast it to the element type (default, 7.0.1 behavior)
        case legacy

        /// Convert the raw JSON value into the declared element type
        case convert
    }
}
