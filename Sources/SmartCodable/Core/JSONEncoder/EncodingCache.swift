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
    
    /// Caches a snapshot for an Encodable type.
    ///
    /// Takes `Any.Type` so callers can pass the *dynamic* type of an
    /// `Encodable` existential (e.g. a model stored in `[String: Encodable]`).
    func cacheSnapshot(for type: Any.Type, codingPath: [CodingKey]) {
        if let object = type as? SmartEncodable.Type {

            var snapshot = EncodingSnapshot()
            snapshot.objectType = object
            snapshot.codingPath = codingPath
            snapshot.transformers = object.mappingForValue()
            snapshots.append(snapshot)
        }
    }

    /// Removes the most recent snapshot for the given type
    func removeSnapshot(for type: Any.Type) {
        if type is SmartEncodable.Type {
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

        return transformers.first { transformer in
            transformerMatches(transformer, key: lastKey.stringValue, objectType: snapshot.objectType)
        }
    }

    /// 一个 transformer 只属于它自己的 location。
    /// key 映射的别名必须映射到该 transformer 的 location 才算命中，
    /// 不能因为“当前 key 是某个映射的别名”就返回第一个 transformer。
    private func transformerMatches(
        _ transformer: SmartValueTransformer,
        key: String,
        objectType: (any SmartEncodable.Type)?
    ) -> Bool {
        if transformer.location.stringValue == key { return true }
        guard let mappings = objectType?.mappingForKey() else { return false }
        return mappings.contains { mapping in
            mapping.to.stringValue == transformer.location.stringValue
            && mapping.from.contains(key)
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

        guard let key = key else { return nil }
        guard let tranformer = valueTransformer(for: key, in: codingPath) else { return nil }
        guard let decoded = transform(decodedValue: value, performer: tranformer.performer) else { return nil }
        return JSONValue.make(decoded)
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


