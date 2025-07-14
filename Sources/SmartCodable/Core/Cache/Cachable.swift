//
//  Cachable.swift
//  SmartCodable
//
//  Created by Mccc on 2024/6/3.
//

import Foundation

/// A protocol defining caching capabilities for model snapshots
/// Used to maintain state during encoding/decoding operations
protocol Cachable {
            
    associatedtype SomeSnapshot: Snapshot

    /// Array of snapshots representing the current parsing stack
    /// - Note: Using an array prevents confusion with multi-level nested models
    var snapshots: [SomeSnapshot] { set get }

    
    /// Caches a new snapshot for the given type at the specified decoding path.
    ///
    /// This method records a snapshot of the decoding context for a specific model type.
    ///
    /// - Parameters:
    ///   - type: The model type being decoded. The snapshot will be associated with this type.
    ///   - codingPath: The current decoding path, used to identify where in the JSON hierarchy this snapshot applies.
    ///                 This allows later lookup of initial values or metadata by matching decoding paths.
    func cacheSnapshot<T>(for type: T.Type, codingPath: [CodingKey])
    
    /// Removes the snapshot for the given type
    /// - Parameter type: The model type to remove from cache
    mutating func removeSnapshot<T>(for type: T.Type)
}


extension Cachable {
    
    /// 根据解码路径查找对应的快照容器。
    ///
    /// 该方法用于在内部缓存的快照列表中，查找与传入 `codingPath` 精确匹配的 `DecodingSnapshot`。
    /// 快照用于缓存某一解码路径下的初始值或上下文信息，便于后续访问或懒加载。
    ///
    /// - Parameter codingPath: 当前字段或容器所在的完整解码路径。
    /// - Returns: 匹配路径的快照对象，若不存在则返回 `nil`。
    func findSnapShot(with codingPath: [CodingKey]) -> SomeSnapshot? {
        return snapshots.first { codingPathEquals($0.codingPath, codingPath) }
    }
    
    private func codingPathEquals(_ lhs: [CodingKey], _ rhs: [CodingKey]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for (l, r) in zip(lhs, rhs) {
            if l.stringValue != r.stringValue || l.intValue != r.intValue {
                return false
            }
        }
        return true
    }
}


/// Represents a snapshot of model state during encoding/decoding
protocol Snapshot {
    
    associatedtype ObjectType
    
    /// The current type being encoded/decoded
    var objectType: ObjectType? { set get }

    var codingPath: [CodingKey] { get set }
    
    /// String representation of the object type
    var objectTypeName: String? { get }
    
    /// Records the custom transformer for properties
    var transformers: [SmartValueTransformer]? { set get }
}

extension Snapshot {
    var objectTypeName: String? {
        if let t = objectType {
            return String(describing: t)
        }
        return nil
    }
}
