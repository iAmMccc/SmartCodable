//
//  SmartUpdater.swift
//  SmartCodable
//
//  Created by Mccc on 2024/5/30.
//

import Foundation


public struct SmartUpdater<T: SmartCodableX> {
    
    /// This method is used to parse JSON data from a Data object and use the resulting dictionary to update a target object.
    /// - Parameters:
    ///   - dest: A reference to the target object (the inout keyword indicates that this object will be modified within the method).
    ///   - src: A Data object containing the JSON data.
    public static func update(_ dest: inout T, from src: Data?) {
        
        guard let src = src else { return }
        
        guard let dict = try? JSONSerialization.jsonObject(with: src, options: .mutableContainers) as? [String: Any] else {
            return
        }
        update(&dest, from: dict)
    }
    
    
    /// This method is used to parse JSON data from a Data object and use the resulting dictionary to update a target object.
    /// - Parameters:
    ///   - dest: A reference to the target object (the inout keyword indicates that this object will be modified within the method).
    ///   - src: A String object containing the JSON data.
    public static func update(_ dest: inout T, from src: String?) {
        
        guard let src = src else { return }
        
        guard let data = src.data(using: .utf8) else { return }
        
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
        
        update(&dest, from: dict)
    }
    
    
    /// This method is used to parse JSON data from a Data object and use the resulting dictionary to update a target object.
    /// - Parameters:
    ///   - dest: A reference to the target object (the inout keyword indicates that this object will be modified within the method).
    ///   - src: A Dictionary object containing the JSON data.
    public static func update(_ dest: inout T, from src: [String: Any]?) {
        guard let model = mergedModel(from: dest, with: src) else { return }
        dest = model
    }

    /// `toDictionary(useMappedKeys: true)` 输出的是 mapping 的第一个别名。
    /// src 可能使用其它别名，直接把 src 合并进去会让旧别名值先被解码器命中，
    /// 新值静默丢失。这里先按 mapping 把 src 归一化到同一个输出 key。
    private static func normalizeSourceKeys(_ src: [String: Any]) -> [String: Any] {
        guard let mappings = T.mappingForKey(), !mappings.isEmpty,
              let json = JSONValue.make(src),
              case .object(let resolved) = KeysMapper.convertFrom(json, type: T.self) else {
            return src
        }

        var normalized = src
        for mapping in mappings {
            guard let canonical = mapping.from.first,
                  let selected = resolved[mapping.to.stringValue] else { continue }
            normalized[canonical] = selected.toFoundation()
        }
        return normalized
    }

    /// Update a model and explicitly restore runtime state excluded from Codable.
    ///
    /// `preserving` runs only after decoding succeeds, before replacing `dest`.
    /// Callers decide how to match and restore nested models or array elements.
    public static func update(
        _ dest: inout T,
        from src: [String: Any]?,
        preserving: (inout T, T) -> Void
    ) {
        guard var model = mergedModel(from: dest, with: src) else { return }
        preserving(&model, dest)
        dest = model
    }

    public static func update(
        _ dest: inout T,
        from src: Data?,
        preserving: (inout T, T) -> Void
    ) {
        guard let src,
              let dict = try? JSONSerialization.jsonObject(with: src, options: .mutableContainers) as? [String: Any] else {
            return
        }
        update(&dest, from: dict, preserving: preserving)
    }

    public static func update(
        _ dest: inout T,
        from src: String?,
        preserving: (inout T, T) -> Void
    ) {
        guard let src, let data = src.data(using: .utf8) else { return }
        update(&dest, from: data, preserving: preserving)
    }

    private static func mergedModel(from dest: T, with src: [String: Any]?) -> T? {
        guard let src, var dictionary = dest.toDictionary(useMappedKeys: true) else {
            return nil
        }
        updateDict(&dictionary, from: normalizeSourceKeys(src))
        return T.deserialize(from: dictionary)
    }
}

extension SmartUpdater {
    
    /// 合并字典，将src合并到dest
    /// - Parameters:
    ///   - dest: 目标字典
    ///   - src: 源字典
//    fileprivate static func updateDict(_ dest: inout [String: Any], from src: [String: Any]) {
//        dest.merge(src) { _, new in
//            return new
//        }
//    }
    
    fileprivate static func updateDict(_ dest: inout [String: Any], from src: [String: Any]) {
        for (key, value) in src {
            if let subDict = value as? [String: Any],
               var existingSubDict = dest[key] as? [String: Any] {
                updateDict(&existingSubDict, from: subDict)
                dest[key] = existingSubDict
            } else {
                dest[key] = value
            }
        }
    }
}
