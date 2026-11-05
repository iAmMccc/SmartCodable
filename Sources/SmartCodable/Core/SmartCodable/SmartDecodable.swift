//
//  SmartDecodable.swift
//  SmartCodable
//
//  Created by Mccc on 2023/9/4.
//

import Foundation

/**
 A protocol that enhances Swift's Decodable with additional customization options for decoding.
 
 Conforming types gain:
 - Post-decoding mapping callbacks
 - Custom key and value transformation strategies
 - Convenient deserialization methods
 
 Requirements:
 - Implement `didFinishMapping()` for post-processing
 - Optionally provide key/value mapping strategies
 */
public protocol SmartDecodable: Decodable {
    /// Callback invoked after successful decoding for post-processing
    mutating func didFinishMapping()
    
    /// Defines key mapping transformations during decoding
    /// First non-null mapping is preferred
    static func mappingForKey() -> [SmartKeyTransformer]?
    
    /// Defines value transformation strategies during decoding
    static func mappingForValue() -> [SmartValueTransformer]?
    
    init()
}


extension SmartDecodable {
    public mutating func didFinishMapping() { }
    public static func mappingForKey() -> [SmartKeyTransformer]? { return nil }
    public static func mappingForValue() -> [SmartValueTransformer]? { return nil }
}


/// Options for SmartCodable parsing
public enum SmartDecodingOption: Hashable {
    
    
    /// The default policy for date is ReferenceDate (January 1, 2001 00:00:00 UTC), in seconds.
    case date(JSONDecoder.DateDecodingStrategy)
    
    case data(JSONDecoder.SmartDataDecodingStrategy)
    
    case float(JSONDecoder.NonConformingFloatDecodingStrategy)
    
    /// The mapping strategy for keys during parsing
    case key(JSONDecoder.SmartKeyDecodingStrategy)
    
    /// 附加用于日志系统的上下文信息，例如网络请求的 URL、参数、调用位置等。
    case logContext(header: String, footer: String)
    
    /// Handles the hash value, ignoring the impact of associated values.
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .date:
            hasher.combine(0)
        case .data:
            hasher.combine(1)
        case .float:
            hasher.combine(2)
        case .key:
            hasher.combine(3)
        case .logContext:
            hasher.combine(4)
        }
    }
    
    public static func == (lhs: SmartDecodingOption, rhs: SmartDecodingOption) -> Bool {
        switch (lhs, rhs) {
        case (.date, .date):
            return true
        case (.data, .data):
            return true
        case (.float, .float):
            return true
        case (.key, .key):
            return true
        case (.logContext, .logContext):
            return true
        default:
            return false
        }
    }
}


extension SmartDecodable {
    
    /// Deserializes into a model
    /// - Parameter dict: Dictionary
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Model
    public static func deserialize(from dict: [String: Any]?, designatedPath: String? = nil,  options: Set<SmartDecodingOption>? = nil) -> Self? {
        
        guard let _input = JSONExtractor.extract(from: dict, by: designatedPath, on: Self.self) else {
            return nil
        }
        
        return _deserializeDict(input: _input, type: Self.self, options: options)
    }
    
    /// Deserializes into a model
    /// - Parameter json: JSON string
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Model
    public static func deserialize(from json: String?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        
        guard let _input = JSONExtractor.extract(from: json, by: designatedPath, on: Self.self) else {
            return nil
        }
        
        return _deserializeDict(input: _input, type: Self.self, options: options)
    }
    
    
    /// Deserializes into a model
    /// - Parameter data: Data
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Model
    public static func deserialize(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        
        guard let _input = JSONExtractor.extract(from: data, by: designatedPath, on: Self.self) else {
            return nil
        }
        
        return _deserializeDict(input: _input, type: Self.self, options: options)
    }
    
    
    /// Deserializes into a model
    /// - Parameter data: Data
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Model
    public static func deserializePlist(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        
        guard let _plistObject = data?.tranformToJSONData(type: Self.self) else { return nil }
        
        guard let _input = JSONExtractor.extract(from: _plistObject, by: designatedPath, on: Self.self) else {
            return nil
        }
        
        return _deserializeDict(input: _input, type: Self.self, options: options)
    }

}


extension Array where Element: SmartDecodable {
    
    /// Deserializes into an array of models
    /// - Parameter array: Array
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Array of models
    public static func deserialize(from array: [Any]?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        
        guard let _input = JSONExtractor.extract(from: array, by: designatedPath, on: Self.self) else {
            return nil
        }
        return _deserializeArray(input: _input, type: Self.self, options: options)
    }
    
    
    /// Deserializes into an array of models
    /// - Parameter json: JSON string
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Only one enumeration item is allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Array of models
    public static func deserialize(from json: String?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        
        guard let _input = JSONExtractor.extract(from: json, by: designatedPath, on: Self.self) else {
            return nil
        }
        return _deserializeArray(input: _input, type: Self.self, options: options)
    }
    
    /// Deserializes into an array of models
    /// - Parameter data: Data
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Array of models
    public static func deserialize(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        
        guard let _input = JSONExtractor.extract(from: data, by: designatedPath, on: Self.self) else {
            return nil
        }
        return _deserializeArray(input: _input, type: Self.self, options: options)
    }
    
    /// Deserializes into an array of models
    /// - Parameter data: Data
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Array of models
    public static func deserializePlist(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        
        guard let _plistObject = data?.tranformToJSONData(type: Self.self) else {
            return nil
        }
        
        guard let _input = JSONExtractor.extract(from: _plistObject, by: designatedPath, on: Self.self) else {
            return nil
        }
        return _deserializeArray(input: _input, type: Self.self, options: options)
    }
}


// MARK: - 内部实现
/// 解析Model类型
fileprivate func _deserializeDict<T>(input: Any, type: T.Type, options: Set<SmartDecodingOption>? = nil) -> T? where T: SmartDecodable {

    do {
        let _decoder = createDecoder(type: type, options: options)
        var obj = try _decoder.smartDecode(type, from: input)
        obj.didFinishMapping()
        return obj
    } catch {
        return nil
    }
}

/// 解析[Model]类型
fileprivate func _deserializeArray<T>(input: Any, type: [T].Type, options: Set<SmartDecodingOption>? = nil) -> [T]? where T: SmartDecodable {

    do {
        let _decoder = createDecoder(type: type, options: options)
        
        let obj = try _decoder.smartDecode(type, from: input)
        return obj
        
    } catch {
        return nil
    }
}


fileprivate func createDecoder<T>(type: T.Type, options: Set<SmartDecodingOption>? = nil) -> SmartJSONDecoder {
    let _decoder = SmartJSONDecoder()
    
    if let _options = options {
        for _option in _options {
            switch _option {
            case .data(let strategy):
                _decoder.smartDataDecodingStrategy = strategy
                
            case .date(let strategy):
                _decoder.smartDateDecodingStrategy = strategy
                
            case .float(let strategy):
                _decoder.nonConformingFloatDecodingStrategy = strategy
            case .key(let strategy):
                _decoder.smartKeyDecodingStrategy = strategy
            case .logContext(let header, let footer):
                var userInfo = _decoder.userInfo
                if let headerKey = CodingUserInfoKey.logContextHeader {
                    userInfo.updateValue(header, forKey: headerKey)
                }
                
                if let footerKey = CodingUserInfoKey.logContextFooter {
                    userInfo.updateValue(footer, forKey: footerKey)
                }
                _decoder.userInfo = userInfo
            }
        }
    }
    
    return _decoder
}





