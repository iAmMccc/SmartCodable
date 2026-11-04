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
    
    func withSnapshot<Result>(for type: Any.Type, codingPath: [CodingKey],
                              _ body: () throws -> Result) rethrows -> Result {
        cacheSnapshot(for: type, codingPath: codingPath)
        defer { removeSnapshot(for: type) }
        return try body()
    }

    /// Caches a snapshot for an Encodable type.
    ///
    /// Takes `Any.Type` so callers can pass the *dynamic* type of an
    /// `Encodable` existential (e.g. a model stored in `[String: Encodable]`).
    private func cacheSnapshot(for type: Any.Type, codingPath: [CodingKey]) {
        if let object = type as? SmartEncodable.Type {

            var snapshot = EncodingSnapshot()
            snapshot.objectType = object
            snapshot.codingPath = codingPath
            snapshot.transformers = object.mappingForValue()
            snapshots.append(snapshot)
        }
    }

    /// Removes the most recent snapshot for the given type
    private func removeSnapshot(for type: Any.Type) {
        if type is SmartEncodable.Type {
            if snapshots.count > 0 {
                snapshots.removeLast()
            }
        }
    }
}


extension EncodingCache {
    /// Containers pass the original CodingKey; output aliases must never select
    /// a transformer belonging to a different model field.
    func valueTransformer(for key: CodingKey?, in containerPath: [CodingKey]) -> SmartValueTransformer? {
        guard let key, let snapshot = findSnapShot(with: containerPath) else { return nil }
        return snapshot.transformers?.first { $0.location.stringValue == key.stringValue }
    }
}


/// Snapshot of encoding state for a particular model
struct EncodingSnapshot: Snapshot {
    var objectType: (any SmartEncodable.Type)?
    
    typealias ObjectType = SmartEncodable.Type
        
    var codingPath: [any CodingKey] = []
    
    var transformers: [SmartValueTransformer]?
}


