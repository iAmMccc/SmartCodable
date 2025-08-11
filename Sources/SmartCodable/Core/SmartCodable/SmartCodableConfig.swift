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
    public static var numberStrategy: NumberConversionStrategy {
        get { _numberConversionStrategy }
        set {_numberConversionStrategy = newValue }
    }


    private static var _numberConversionStrategy = NumberConversionStrategy.strict

    
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
