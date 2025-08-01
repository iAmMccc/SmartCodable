//
//  EncodingCache.swift
//  SmartCodable
//
//  Created by Mccc on 2024/6/3.
//

import Foundation


/// Caches state during encoding operations
class EncodingCache: Cachable {
    typealias SomeSnapshot = EncodingSnapshot

    var snapshots: [EncodingSnapshot] = []
    
    /// Caches a snapshot for an Encodable type
    func cacheSnapshot<T>(for type: T.Type, codingPath: [CodingKey]) {
        if let object = type as? SmartEncodable.Type {
            
            var snapshot = EncodingSnapshot()
            snapshot.objectType = object
            snapshot.codingPath = codingPath
            snapshot.transformers = object.mappingForValue()
            snapshots.append(snapshot)
        }
    }
    
    /// Removes the most recent snapshot for the given type
    func removeSnapshot<T>(for type: T.Type) {
        if let _ = T.self as? SmartEncodable.Type {
            if snapshots.count > 0 {
                snapshots.removeLast()
            }
        }
    }
}


extension EncodingCache {
    /// 获取对应的值解析器
    func valueTransformer(for key: CodingKey?, in containerPath: [CodingKey]) -> SmartValueTransformer? {
        guard let lastKey = key else { return nil }
        
        guard let snapshot = findSnapShot(with: containerPath) else { return nil }
        
        guard let transformers = snapshot.transformers, !transformers.isEmpty else { return nil }
        
        
        // 提前解析 key 映射（避免每次遍历 transformer 都重新计算）
        let keyMappings: Set<String> = {
            guard let mappings = snapshot.objectType?.mappingForKey() else { return [] }
            return Set(mappings.flatMap { $0.from })
        }()
        
        let transformer = transformers.first(where: { transformer in
            transformer.location.stringValue == lastKey.stringValue
            || keyMappings.contains(lastKey.stringValue)
        })

        return transformer
    }
}


extension EncodingCache {
    
    /// Transforms a value to JSON using the appropriate transformer
    /// - Parameters:
    ///   - value: The value to transform
    ///   - key: The associated coding key
    /// - Returns: The transformed JSON value or nil if no transformer applies
    func tranform(from value: Any, with key: CodingKey?, codingPath: [CodingKey]) -> JSONValue? {
        
        guard let top = findSnapShot(with: codingPath), let key = key else { return nil }
                
        // 查找对应的值转换器
        let wantKey = key.stringValue
        let targetTran = top.transformers?.first(where: { transformer in
            if wantKey == transformer.location.stringValue {
                return true
            } else {
                if let keyTransformers = top.objectType?.mappingForKey() {
                    for keyTransformer in keyTransformers {
                        if keyTransformer.from.contains(wantKey) {
                            return true
                        }
                    }
                }
                return false
            }
        })
        
        if let tran = targetTran, let decoded = transform(decodedValue: value, performer: tran.performer) {
            return JSONValue.make(decoded)
        }
        
        return nil
    }
    
    /// Performs the actual value transformation
    private func transform<Performer: ValueTransformable>(decodedValue: Any, performer: Performer) -> Any? {
        // 首先检查是否是属性包装器
        if let propertyWrapper = decodedValue as? any PropertyWrapperable {
            let wrappedValue = propertyWrapper.wrappedValue
            guard let value = wrappedValue as? Performer.Object else {
                return nil
            }
            return performer.transformToJSON(value)
        } else {
            guard let value = decodedValue as? Performer.Object else { return nil }
            return performer.transformToJSON(value)
        }
    }
}




/// Snapshot of encoding state for a particular model
struct EncodingSnapshot: Snapshot {
    var objectType: (any SmartEncodable.Type)?
    
    typealias ObjectType = SmartEncodable.Type
        
    var codingPath: [any CodingKey] = []
    
    var transformers: [SmartValueTransformer]?
}


