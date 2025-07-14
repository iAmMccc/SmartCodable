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
    
    /// Transforms a value to JSON using the appropriate transformer
    /// - Parameters:
    ///   - value: The value to transform
    ///   - key: The associated coding key
    /// - Returns: The transformed JSON value or nil if no transformer applies
    func tranform(from value: Any, with key: CodingKey?, codingPath: [CodingKey]) -> JSONValue? {
        
        guard let top = findSnapShot(with: codingPath), let key = key else { return nil }
                
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
    private func transform<Transform: ValueTransformable>(decodedValue: Any, performer: Transform) -> Any? {
        // 首先检查是否是属性包装器
        if let propertyWrapper = decodedValue as? any PropertyWrapperInitializable {
            let wrappedValue = propertyWrapper.wrappedValue
            guard let value = wrappedValue as? Transform.Object else { return nil }
            return performer.transformToJSON(value)
        } else {
            guard let value = decodedValue as? Transform.Object else { return nil }
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


