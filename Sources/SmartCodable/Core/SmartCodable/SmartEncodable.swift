//
//  SmartEncodable.swift
//  SmartCodable
//
//  Created by Mccc on 2023/9/4.
//

import Foundation


public protocol SmartEncodable: Encodable {
    /// The callback for when mapping is complete
    mutating func didFinishMapping()
  
    /// The mapping relationship of decoding keys
    static func mappingForKey() -> [SmartKeyTransformer]?
    
    /// The strategy for decoding values
    static func mappingForValue() -> [SmartValueTransformer]?
    
    init()
}


/// Options for SmartCodable parsing
public enum SmartEncodingOption: Hashable {
    
    
    /// date的默认策略是ReferenceDate（参考日期是指2001年1月1日 00:00:00 UTC），以秒为单位。
    case date(JSONEncoder.DateEncodingStrategy)
    
    case data(JSONEncoder.SmartDataEncodingStrategy)
    
    case float(JSONEncoder.NonConformingFloatEncodingStrategy)
    
    /// The mapping strategy for keys during parsing
    case key(JSONEncoder.SmartKeyEncodingStrategy)
    
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
        }
    }
    
    public static func == (lhs: SmartEncodingOption, rhs: SmartEncodingOption) -> Bool {
        switch (lhs, rhs) {
        case (.date, .date):
            return true
        case (.data, .data):
            return true
        case (.float, .float):
            return true
        case (.key, .key):
            return true
        default:
            return false
        }
    }
}


extension SmartEncodable {

    /// Serializes into a dictionary
    /// - Parameter useMappedKeys: Whether to use the mapped key during encoding. The default value is false.
    ///   -- CodingKeys.array <--- "out_array", 为ture时，使用"out_array"。
    /// - Parameter options: encoding options
    /// - Returns: dictionary
    
    /// Serializes the object into a dictionary representation.
    ///
    /// - Parameters:
    ///   - useMappedKeys: Determines whether to use source field names defined in `SmartKeyTransformer` during encoding.
    ///     - When `true`: Uses the first field name from `SmartKeyTransformer.from` (e.g., given `property <--- ["json_field", "alt_field"]`, uses `"json_field"`)
    ///     - When `false` (default): Uses the destination property name from `SmartKeyTransformer.to`
    ///   - options: Optional set of encoding configuration options that control serialization behavior
    ///
    /// - Returns: A dictionary representation of the object, or `nil` if encoding fails
    ///
    /// - Example:
    ///   ```
    ///   struct Model: SmartCodableX {
    ///       var data: String
    ///       static func mappingForKey() -> [SmartKeyTransformer]? {
    ///           [CodingKeys.data <--- ["json_data", "alt_data"]]
    ///       }
    ///   }
    ///
    ///   let model = Model(data: "value")
    ///   let dict1 = model.toDictionary() // ["data": "value"]
    ///   let dict2 = model.toDictionary(useMappedKeys: true) // ["json_data": "value"]
    ///   ```
    public func toDictionary(useMappedKeys: Bool = false, options: Set<SmartEncodingOption>? = nil) -> [String: Any]? {
        return _transformToJson(self, type: Self.self, useMappedKeys: useMappedKeys, options: options)
    }
    
    /// Serializes into a JSON string
    /// - Parameter useMappedKeys: Whether to use the mapped key during encoding. The default value is false.
    /// - Parameter options: encoding options
    /// - Parameter prettyPrint: Whether to format print (adds line breaks in the JSON)
    /// - Returns: JSON string
    public func toJSONString(useMappedKeys: Bool = false, options: Set<SmartEncodingOption>? = nil, prettyPrint: Bool = false) -> String? {
        if let anyObject = toDictionary(useMappedKeys: useMappedKeys, options: options) {
            return _transformToJsonString(object: anyObject, prettyPrint: prettyPrint, type: Self.self)
        }
        return nil
    }
}


extension Array where Element: SmartEncodable {
    /// Serializes into a array
    /// - Parameter useMappedKeys: Whether to use the mapped key during encoding. The default value is false.
    /// - Returns: array
    public func toArray(useMappedKeys: Bool = false, options: Set<SmartEncodingOption>? = nil) -> [Any]? {
        return _transformToJson(self,type: Element.self, useMappedKeys: useMappedKeys, options: options)
    }
    
    /// Serializes into a JSON string
    /// - Parameter useMappedKeys: Whether to use the mapped key during encoding. The default value is false.
    /// - Parameter options: encoding options
    /// - Parameter prettyPrint: Whether to format print (adds line breaks in the JSON)
    /// - Returns: JSON string
    public func toJSONString(useMappedKeys: Bool = false, options: Set<SmartEncodingOption>? = nil, prettyPrint: Bool = false) -> String? {
        if let anyObject = toArray(useMappedKeys: useMappedKeys, options: options) {
            return _transformToJsonString(object: anyObject, prettyPrint: prettyPrint, type: Element.self)
        }
        return nil
    }
}



fileprivate func _transformToJson<T>(_ some: Encodable, type: Any.Type, useMappedKeys: Bool, options: Set<SmartEncodingOption>? = nil) -> T? {
    
    let jsonEncoder = SmartJSONEncoder()
    
    if useMappedKeys, let key = CodingUserInfoKey.useMappedKeys {
        var userInfo = jsonEncoder.userInfo
        userInfo.updateValue(true, forKey: key)
        jsonEncoder.userInfo = userInfo
    }
    
    if let _options = options {
        for _option in _options {
            switch _option {
            case .data(let strategy):
                jsonEncoder.smartDataEncodingStrategy = strategy
                
            case .date(let strategy):
                jsonEncoder.dateEncodingStrategy = strategy
                
            case .float(let strategy):
                jsonEncoder.nonConformingFloatEncodingStrategy = strategy
            case .key(let strategy):
                jsonEncoder.smartKeyEncodingStrategy = strategy
            }
        }
    }
    
    
    if let jsonData = try? jsonEncoder.encode(some) {
        do {
            let json = try JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed)
            if let temp = json as? T {
                return temp
            } else {
                SmartSentinel.monitorAndPrint(debugDescription: "\(json)) is not a valid Type, wanted \(T.self) type.", error: nil, in: type)
            }
        } catch {
            SmartSentinel.monitorAndPrint(debugDescription: "'JSONSerialization.jsonObject(:)' falied", error: nil, in: type)
        }
    }
    return nil
}



fileprivate func _transformToJsonString(object: Any, prettyPrint: Bool = false, type: Any.Type) -> String? {
    if JSONSerialization.isValidJSONObject(object) {
        do {
            let options: JSONSerialization.WritingOptions = prettyPrint ? [.prettyPrinted] : []
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: options)
            return String(data: jsonData, encoding: .utf8)
            
        } catch {
            SmartSentinel.monitorAndPrint(debugDescription: "'JSONSerialization.data(:)' falied", error: error, in: type)
        }
    } else {
        SmartSentinel.monitorAndPrint(debugDescription: "\(object)) is not a valid JSON Object", error: nil, in: type)
    }
    return nil
}
