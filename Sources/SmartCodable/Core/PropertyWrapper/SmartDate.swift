//
//  SmartDate.swift
//  SmartCodable
//
//  Created by qixin on 2025/4/30.
//

import Foundation
import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@propertyWrapper
public struct SmartDate: PropertyWrapperable {
    
    public var wrappedValue: Date?
    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
        self.encodeFormat = nil
    }
    
    public func wrappedValueDidFinishMapping() -> SmartDate? {
        // Date类型不需要DidFinishMapping处理。
        return nil
    }
    public static func createInstance(with value: Any) -> SmartDate? {
        if let value = value as? Date {
            return SmartDate(wrappedValue: value)
        }
        return nil
    }
    

    
    private var encodeFormat: DateStrategy?

    public init(wrappedValue: Date?, encodeFormat: SmartDate.DateStrategy? = nil) {
        self.wrappedValue = wrappedValue
        self.encodeFormat = encodeFormat
    }
}


extension SmartDate: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        let raw: Any
        if let double = try? container.decode(Double.self) {
            raw = double
        } else if let string = try? container.decode(String.self) {
            raw = string
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date value")
        }
        
        guard let (date, format) = DateParser.parse(raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(raw)")
        }
        
        self.wrappedValue = date
        if self.encodeFormat == nil {
            self.encodeFormat = format
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let date = wrappedValue else {
            return try container.encodeNil()
        }

        let format = encodeFormat ?? .timestamp
        
        switch format {
        case .timestamp:
            try container.encode(date.timeIntervalSince1970)
        case .timestampMilliseconds:
            try container.encode(Int(date.timeIntervalSince1970 * 1000))
        case .iso8601:
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: date))
        case .formatted(let format):
            try container.encode(format.string(from: date))
        }
    }
}


extension SmartDate {
    public enum DateStrategy {
        case timestamp                  // seconds
        case timestampMilliseconds      // milliseconds
        case iso8601
        case formatted(DateFormatter)   // custom date format
    }
}


struct DateParser {
    private static let knownFormats: [String] = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd",
        "yyyy/MM/dd",
        "MM/dd/yyyy",
        "yyyy-MM-dd HH:mm",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    ]

    // https://developer.apple.com/library/archive/qa/qa1480/_index.html
    private static let locale = Locale(identifier: "en_US_POSIX")

    static func parse(_ raw: Any) -> (Date, SmartDate.DateStrategy)? {
        if let result = parseTimestamp(from: raw) {
            return result
        }

        if let string = raw as? String {
            // try knownFormats
            let formatter = DateFormatter()
            formatter.locale = locale
            for format in knownFormats {
                formatter.dateFormat = format
                if let date = formatter.date(from: string) {
                    return (date, .formatted(formatter))
                }
            }

            // 尝试 ISO8601 yyyy-MM-dd'T'HH:mm:ssZ
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: string) {
                return (date, .iso8601)
            }
        }

        return nil
    }
    
    private static func parseTimestamp(from raw: Any) -> (Date, SmartDate.DateStrategy)? {
        if let double = raw as? Double ?? Double(raw as? String ?? "") {
            if double > 1_000_000_000_000 {
                return (Date(timeIntervalSince1970: double / 1000), .timestampMilliseconds)
            } else {
                return (Date(timeIntervalSince1970: double), .timestamp)
            }
        }
        return nil
    }
}
