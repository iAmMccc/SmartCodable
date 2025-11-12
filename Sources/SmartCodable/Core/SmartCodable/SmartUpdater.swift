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
        guard let src = src else { return }
        var destDict = dest.toDictionary(useMappedKeys: true) ?? [:]
        updateDict(&destDict, from: src)
        if let model = T.deserialize(from: destDict) {
            dest = model
        }
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
