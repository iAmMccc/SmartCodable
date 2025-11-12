//
//  KeysMapper.swift
//  SmartCodable
//
//  Created by Mccc on 2024/5/27.
//

import Foundation

/// Handles key mapping and conversion for JSON values during decoding
struct KeysMapper {
    
    /// Converts JSON values according to the target type's key mapping rules
    /// - Parameters:
    ///   - jsonValue: The original JSON value to convert
    ///   - type: The target type for decoding
    /// - Returns: Converted JSON value or nil if conversion fails
    static func convertFrom(_ jsonValue: JSONValue, type: Any.Type) -> JSONValue? {
        
        // Type is not Model, no key renaming needed
        guard let type = type as? SmartDecodable.Type else { return jsonValue }
        
        switch jsonValue {
        case .string(let stringValue):
            // Handle string values that might contain JSON
            if let value = parseJSON(from: stringValue, as: type) {
                return JSONValue.make(value)
            }
            
        case .object(let dictValue):
            // Convert dictionary keys according to mapping rules
            if let dict = mapDictionary(dict: dictValue, using: type) as? [String: JSONValue] {
                return JSONValue.object(dict)
            }
            
        default:
            break
        }
        return nil
    }
    
    /// Parses a string into JSON object and applies key mapping
    private static func parseJSON(from string: String, as type: SmartDecodable.Type) -> Any? {
        guard let jsonObject = string.toJSONObject() else { return string }
        if let dict = jsonObject as? [String: Any] {
            // Apply key mapping to dictionary
            return mapDictionary(dict: dict, using: type)
        } else {
            return jsonObject
        }
    }
    
    /// Applies key mapping rules to a dictionary
    private static func mapDictionary(dict: [String: Any], using type: SmartDecodable.Type) -> [String: Any]? {
        
        guard let mappings = type.mappingForKey(), !mappings.isEmpty else { return nil }
        
        var newDict = dict
        mappings.forEach { mapping in
            let newKey = mapping.to.stringValue
            
            /**
             * Check if the original field is an interference field (exists in mapping relationship)
             * Interference field scenario: Note cases like CodingKeys.name <--- ["newName"]
             * Valid field scenario: Note cases like CodingKeys.name <--- ["name", "newName"]
             */
            if !(mapping.from.contains(newKey)) {
                newDict.removeValue(forKey: newKey)
            }
            
            // break effect: Prefer the first non-null field
            for oldKey in mapping.from {
                // Mapping exists at current level
                if let value = dict[oldKey] as? JSONValue, value != .null {
                    newDict[newKey] = value
                    break
                }
                
                // Mapping requires cross-level path handling
                if let pathValue = dict.getValue(forKeyPath: oldKey) {
                    newDict.updateValue(pathValue, forKey: newKey)
                    break
                }
            }
        }
        return newDict
    }
}



extension Dictionary {
    
    /// Retrieves the value corresponding to the path in the dictionary.
    ///  let dict = [
    ///      "inDict": [
    ///         "name": "Mccc"
    ///      ]
    ///  ]
    ///
    ///  keyPath is “inDict.name”
    ///
    ///  result： Mccc
    ///
    fileprivate func getValue(forKeyPath keyPath: String) -> Any? {
        guard keyPath.contains(".") else { return nil }
        let keys = keyPath.components(separatedBy: ".")
        var currentAny: Any = self
        for key in keys {
            if let currentDict = currentAny as? [String: Any] {
                if let value = currentDict[key] {
                    currentAny = value
                } else {
                    return nil
                }
            } else if case JSONValue.object(let object) = currentAny, let temp = object[key] {
                currentAny = temp
            } else {
                return nil
            }
        }
        return currentAny
    }
}



extension String {
    func toJSONObject() -> Any? {
        return data(using: .utf8).flatMap { try? JSONSerialization.jsonObject(with: $0) }
    }
}
