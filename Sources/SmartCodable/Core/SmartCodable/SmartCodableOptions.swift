//
//  SmartCoding.swift
//  BTCodable
//
//  Created by Mccc on 2023/8/1.
//



/// Global coding/decoding configuration namespace for SmartCodable
public struct SmartCodableOptions {
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
    public static var numberStrategy: NumberConversionStrategy = .strict


    /// Whether to treat JSON `null` as a decoded value for `Any`-typed property wrappers (default: `true`)
    ///
    /// 在对使用 `Any`（或 Any 支持的属性包装器）进行解码时，决定是否把 JSON 中的 `null` 当作可被解码并赋值到 `Any` 的值。
    ///
    /// - Behavior:
    ///   - 当为 `true`（默认）时：遇到 JSON 字段值为 `null`，属性包装器**不会**把 `NSNull`/`nil` 赋给目标 `Any`，而是跳过赋值（保持属性的默认值或原有值）。
    ///   - 当为 `false` 时：遇到 JSON 字段值为 `null`，属性包装器会把 `NSNull()`（或解码为 `nil`，取决于你的实现）作为解析结果赋给 `Any`，从而能在运行时检测到该字段为 `null`。
    public static var ignoreNull: Bool = true
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
