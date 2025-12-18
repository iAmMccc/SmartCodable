//
//  SmartHexColor.swift
//  SmartCodable
//
//  Created by dadadongl on 2025/4/22.
//

/**
 * A property wrapper that enables UIColor/NSColor handling in Codable properties by decoding hex strings.
 *
 * Usage Example:
 *
 * ```
 struct SomeModel: SmartCodableX {
     @SmartHexColor
     var titleColor: UIColor? = .white
     @SmartHexColor
     var descColor: UIColor?
 }
 * ```
 */

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
public typealias ColorObject = UIColor
#elseif os(macOS)
import AppKit
public typealias ColorObject = NSColor
#endif



@propertyWrapper
public struct SmartHexColor: PropertyWrapperable {
    
    public var wrappedValue: ColorObject?
    public init(wrappedValue: ColorObject?) {
        self.wrappedValue = wrappedValue
    }
    
    public static func createInstance(with value: Any) -> SmartHexColor? {
        if let value = value as? ColorObject {
            return SmartHexColor(wrappedValue: value)
        }
        return nil
    }
    
    public func wrappedValueDidFinishMapping() -> SmartHexColor? {
        return nil
    }
    
    
    var encodeHexFormat: HexFormat?

    public init(wrappedValue: ColorObject?, encodeHexFormat: HexFormat? = nil) {
        self.wrappedValue = wrappedValue
        self.encodeHexFormat = encodeHexFormat
    }
}

extension SmartHexColor: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hexString = try container.decode(String.self)
        
        
        guard let impl = decoder as? JSONDecoderImpl else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode SmartHexColor from '\(hexString)'. Supported formats: HexFormat."
            )
        }
        
        guard
            let format = SmartHexColor.HexFormat.format(for: hexString),
            let color = SmartHexColor.toColor(from: hexString, format: format)
        else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode SmartHexColor from '\(hexString)'. Supported formats: HexFormat."
            )
        }

        self.wrappedValue = color
        
        
        /**
         * 虽然初始化赋值时候`public init(wrappedValue: ColorObject?, encodeHexFormat: HexFormat? = nil)` 提供了 `encodeHexFormat`,但是在 `encode` 解析时重新初始化了对象导致赋值的 `encodeHexFormat` 没了。
         * 通过缓存 `Cache` 获取使用者设置的该值。
         * 再赋值到新对象的属性上。
         */
        if let arr = impl.codingPath.removeFromEnd(1),
           let hexColor: SmartHexColor = try? impl.cache.initialValue(forKey: impl.codingPath.last, codingPath: arr) {
            self.encodeHexFormat = hexColor.encodeHexFormat
        }
    }
    
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        guard let color = wrappedValue else {
            return try container.encodeNil() // 更明确地记录 nil
        }

        let format = encodeHexFormat ?? .rrggbb(.none)
        
        guard let hexString = SmartHexColor.toHexString(from: color, format: format) else {
            throw EncodingError.invalidValue(
                color,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Failed to convert color to hex string with format \(format)"
                )
            )
        }
        
        try container.encode(hexString)
    }
}



extension SmartHexColor {
    
    public static func toColor(from hex: String, format: SmartHexColor.HexFormat) -> ColorObject? {
        // 1. 移除前缀
        let hexString = normalizedHexString(from: hex, prefix: format.prefix)
        
        // 2. 将字符串转换为 UInt64
        guard let hexValue = UInt64(hexString, radix: 16) else { return nil }
        
        // 3. 按格式解析颜色分量
        func component(_ value: UInt64, shift: Int, mask: UInt64) -> CGFloat {
            return CGFloat((value >> shift) & mask) / 255
        }
        
        let r, g, b, a: CGFloat
        
        switch format {
        case .rgb:
            r = CGFloat((hexValue >> 8) & 0xF) / 15
            g = CGFloat((hexValue >> 4) & 0xF) / 15
            b = CGFloat(hexValue & 0xF) / 15
            a = 1.0
            
        case .rgba:
            r = CGFloat((hexValue >> 12) & 0xF) / 15
            g = CGFloat((hexValue >> 8) & 0xF) / 15
            b = CGFloat((hexValue >> 4) & 0xF) / 15
            a = CGFloat(hexValue & 0xF) / 15
            
        case .rrggbb:
            r = component(hexValue, shift: 16, mask: 0xFF)
            g = component(hexValue, shift: 8, mask: 0xFF)
            b = component(hexValue, shift: 0, mask: 0xFF)
            a = 1.0
            
        case .rrggbbaa:
            r = component(hexValue, shift: 24, mask: 0xFF)
            g = component(hexValue, shift: 16, mask: 0xFF)
            b = component(hexValue, shift: 8, mask: 0xFF)
            a = component(hexValue, shift: 0, mask: 0xFF)
        }
        
#if os(macOS)
        return NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
#else
        return UIColor(red: r, green: g, blue: b, alpha: a)
#endif
    }
    
    /// 移除前缀并转小写
    private static func normalizedHexString(from hex: String, prefix: String) -> String {
        let trimmedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if !prefix.isEmpty, trimmedHex.hasPrefix(prefix.lowercased()) {
            return String(trimmedHex.dropFirst(prefix.count))
        } else {
            return trimmedHex
        }
    }

    
    static func toHexString(from color: ColorObject, format: SmartHexColor.HexFormat) -> String? {
        guard let components = color.rgbaComponents else { return nil }

        func clamped255(_ value: CGFloat) -> Int {
            return min(max(Int(value * 255), 0), 255)
        }
        
        let r = clamped255(components.r)
        let g = clamped255(components.g)
        let b = clamped255(components.b)
        let a = clamped255(components.a)

        

        switch format {
        case .rgb(let prefix):
            return prefix.rawValue + String(format: "%01X%01X%01X", (r >> 4), (g >> 4), (b >> 4))

        case .rgba(let prefix):
            return prefix.rawValue + String(format: "%01X%01X%01X%01X", (r >> 4), (g >> 4), (b >> 4), (a >> 4))

        case .rrggbb(let prefix):
            return prefix.rawValue + String(format: "%02X%02X%02X", r, g, b)

        case .rrggbbaa(let prefix):
            return prefix.rawValue + String(format: "%02X%02X%02X%02X", r, g, b, a)
        }
    }
}


extension SmartHexColor {
    
    /// 定义 16 进制颜色代码的格式（支持带 `#` 和不带 `#` 的格式）
    ///
    /// ## 格式说明
    /// - **无透明度**：
    ///   - `RGB`：3 位，例如 `F00`（等价于 `FF0000`）
    ///   - `#RGB`：带 `#` 前缀的 3 位，例如 `#F00`
    ///   - `RRGGBB`：6 位，例如 `FF0000`
    ///   - `#RRGGBB`：带 `#` 前缀的 6 位，例如 `#FF0000`
    ///
    /// - **带透明度**：
    ///   - `RGBA`：4 位，例如 `F008`（等价于 `FF000088`）
    ///   - `#RGBA`：带 `#` 前缀的 4 位，例如 `#F008`
    ///   - `RRGGBBAA`：8 位，例如 `FF000080`
    ///   - `#RRGGBBAA`：带 `#` 前缀的 8 位，例如 `#FF000080`
    ///
    /// > 注意：枚举值名称中的 `hash` 表示格式包含 `#` 前缀。
    public enum HexFormat {
        /// 3 位无透明度（如 `F00`）
        case rgb(Prefix)
        
        /// 6 位无透明度（如 `FF0000`）
        case rrggbb(Prefix)
        
        /// 4 位带透明度（如 `F008`）
        case rgba(Prefix)
        
        /// 8 位带透明度（如 `FF000080`）
        case rrggbbaa(Prefix)
        
        
        var prefix: String {
            switch self {
            case .rgb(let prefix):
                return prefix.rawValue
            case .rrggbb(let prefix):
                return prefix.rawValue
            case .rgba(let prefix):
                return prefix.rawValue
            case .rrggbbaa(let prefix):
                return prefix.rawValue
            }
        }
                
        public enum Prefix {
            case hash
            case zeroX
            case none
            
            var rawValue: String {
                switch self {
                case .hash:
                    return "#"
                case .zeroX:
                    return "0x"
                case .none:
                    return ""
                }
            }
        }
        
        /// 根据给定的 hex 字符串，自动识别并返回相应的 `HexFormat`
        static func format(for hexString: String) -> HexFormat? {
            let trimmedHex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            // 判断是否有前缀并根据不同前缀选择不同的处理方法
            if trimmedHex.hasPrefix("#") {
                let pureHex = String(trimmedHex.dropFirst())
                return detectFormat(from: pureHex, withPrefix: .hash)
            } else if trimmedHex.hasPrefix("0x") {
                let pureHex = String(trimmedHex.dropFirst(2))
                return detectFormat(from: pureHex, withPrefix: .zeroX)
            } else {
                return detectFormat(from: trimmedHex, withPrefix: .none)
            }
        }
        
        // 自动识别和推断 HexFormat
        private static func detectFormat(from hex: String, withPrefix prefix: Prefix) -> HexFormat? {
            switch hex.count {
            case 3:
                return .rgb(prefix)
            case 4:
                return .rgba(prefix)
            case 6:
                return .rrggbb(prefix)
            case 8:
                return .rrggbbaa(prefix)
            default:
                return nil
            }
        }
    }
}



extension ColorObject {
    var rgbaComponents: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
#if os(macOS)
        guard let converted = usingColorSpace(.deviceRGB) else { return nil }
        return (converted.redComponent, converted.greenComponent, converted.blueComponent, converted.alphaComponent)
#else
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return (r, g, b, a)
#endif
    }
}
