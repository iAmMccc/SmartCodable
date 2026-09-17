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
    var snapshots: [SomeSnapshot] { get }
}


extension Cachable where SomeSnapshot == EncodingSnapshot {
    
    /// 查找匹配当前编码路径的最新快照（仅用于编码；解码必须使用活跃所有者快照）。
    func findSnapShot(with codingPath: [CodingKey]) -> SomeSnapshot? {
        return snapshots.last { codingPathEquals($0.codingPath, codingPath) }
    }
}

extension Cachable {
    /// 比较两个 codingPath 的层级与键值是否完全一致。
    func codingPathEquals(_ lhs: [CodingKey], _ rhs: [CodingKey]) -> Bool {
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
    
    /// Records the custom transformer for properties
    var transformers: [SmartValueTransformer]? { set get }
}
