//
//  DecodingCache.swift
//  SmartCodable
//
//  Created by Mccc on 2024/3/5.
//

import Foundation


/// Caches default values during decoding operations
/// Used to provide fallback values when decoding fails
class DecodingCache: Cachable {
    
    typealias SomeSnapshot = DecodingSnapshot

    /// 解码快照栈
    private(set) var snapshots: [DecodingSnapshot] = []

    /// 作用域唯一标识递增计数器
    private var nextScopeIdentifier = 0
    /// 当前正在执行解码的活跃所有者栈
    private var activeOwners: [ActiveOwner] = []

    /// 当前活跃所有者栈深度
    var activeOwnerDepth: Int { activeOwners.count }

    /// 在指定类型的快照作用域内执行解码。
    ///
    /// 快照的资格判断、创建与清理全部收口在这里：
    /// 调用方只表达“在该类型的快照作用域内解码”，
    /// 不再手工配对压栈与出栈，抛错路径也会清理本作用域的快照。
    func withSnapshot<T, Result>(
        for type: T.Type,
        codingPath: [CodingKey],
        _ body: () throws -> Result
    ) rethrows -> Result {

        guard let request = snapshotRequest(for: type) else {
            return try body()
        }

        // 同一路径下若该类型尚未在当前作用域执行，则复用作用域；否则分配新作用域
        let currentScope = activeOwners.last(where: {
            codingPathEquals($0.snapshot.codingPath, codingPath)
        })?.scopeIdentifier
        let scopeIdentifier: Int
        if let currentScope,
           !isExecuting(
               request.activeType,
               as: request.mode,
               in: currentScope
           ) {
            scopeIdentifier = currentScope
        } else {
            nextScopeIdentifier += 1
            scopeIdentifier = nextScopeIdentifier
        }

        var createdSnapshots: [DecodingSnapshot] = []
        // 保证同一 (scope, codingPath, objectType) 下快照唯一
        func ownerSnapshot(for objectType: SmartDecodable.Type) -> DecodingSnapshot {
            if let existing = snapshot(
                for: objectType,
                codingPath: codingPath,
                scopeIdentifier: scopeIdentifier
            ) {
                return existing
            }

            let snapshot = DecodingSnapshot()
            snapshot.codingPath = codingPath
            snapshot.objectType = objectType
            snapshot.scopeIdentifier = scopeIdentifier
            snapshots.append(snapshot)
            createdSnapshots.append(snapshot)
            return snapshot
        }

        let activeSnapshot = ownerSnapshot(for: request.activeType)
        // 预声明包装器内层模型的快照（同一作用域），便于后续所有者切换
        if let wrappedType = request.wrappedType {
            _ = ownerSnapshot(for: wrappedType)
        }
        activeOwners.append(ActiveOwner(
            mode: request.mode,
            scopeIdentifier: scopeIdentifier,
            snapshot: activeSnapshot
        ))

        defer {
            assert(activeOwners.last?.snapshot === activeSnapshot,
                   "Active decoding owner is not the one created by this scope")
            if activeOwners.last?.snapshot === activeSnapshot {
                activeOwners.removeLast()
            }

            for created in createdSnapshots.reversed() {
                assert(snapshots.last === created,
                       "Decoding snapshot stack top is not the owner created by this entry")
                if snapshots.last === created {
                    snapshots.removeLast()
                }
            }
        }

        return try body()
    }

    /// 解析目标类型的快照请求，提取活跃所有者类型与内层包装模型类型
    private func snapshotRequest<T>(for type: T.Type) -> SnapshotRequest? {
        let ownerType = type as? SmartDecodable.Type
        let wrappedType = (type as? any PropertyWrapperable.Type)?.wrappedSmartDecodableType
        guard let activeType = ownerType ?? wrappedType else { return nil }

        let distinctWrappedType = wrappedType.flatMap { wrappedType in
            ObjectIdentifier(wrappedType) == ObjectIdentifier(activeType) ? nil : wrappedType
        }
        return SnapshotRequest(
            activeType: activeType,
            wrappedType: distinctWrappedType,
            mode: ownerType == nil ? .wrapperScope : .owner
        )
    }

    /// 判断指定类型是否已经在该作用域内以相同模式处于执行中
    private func isExecuting(
        _ objectType: SmartDecodable.Type,
        as mode: ActiveOwner.Mode,
        in scopeIdentifier: Int
    ) -> Bool {
        activeOwners.contains(where: { active in
            guard active.scopeIdentifier == scopeIdentifier,
                  active.mode == mode,
                  let activeType = active.snapshot.objectType else {
                return false
            }
            return ObjectIdentifier(activeType) == ObjectIdentifier(objectType)
        })
    }

    /// 查找指定作用域、路径与类型的快照
    private func snapshot(
        for objectType: SmartDecodable.Type,
        codingPath: [CodingKey],
        scopeIdentifier: Int
    ) -> DecodingSnapshot? {
        snapshots.last(where: { snapshot in
            guard snapshot.scopeIdentifier == scopeIdentifier,
                  codingPathEquals(snapshot.codingPath, codingPath),
                  let snapshotType = snapshot.objectType else {
                return false
            }
            return ObjectIdentifier(snapshotType) == ObjectIdentifier(objectType)
        })
    }

    /// 获取指定路径下当前活跃所有者的快照
    private func activeSnapshot(at codingPath: [CodingKey]) -> DecodingSnapshot? {
        activeOwners.last(where: {
            codingPathEquals($0.snapshot.codingPath, codingPath)
        })?.snapshot
    }

    /// 获取指定路径下当前正在执行解码的活跃所有者类型（排除预声明但尚未激活的内层包装类型）
    func activeOwner(at codingPath: [CodingKey]) -> SmartDecodable.Type? {
        activeSnapshot(at: codingPath)?.objectType
    }
}

/// 快照构建请求参数
private struct SnapshotRequest {
    /// 待激活的所有者类型
    let activeType: SmartDecodable.Type
    /// 包装器内部嵌套的 SmartDecodable 类型（若存在）
    let wrappedType: SmartDecodable.Type?
    /// 所有者执行模式
    let mode: ActiveOwner.Mode
}

/// 正在执行解码的活跃所有者记录
private struct ActiveOwner {
    enum Mode {
        /// 包装器作用域模式（包装器本身非 SmartDecodable）
        case wrapperScope
        /// 独立所有者模式（模型自身或遵循 SmartDecodable 的双协议包装器）
        case owner
    }

    let mode: Mode
    let scopeIdentifier: Int
    let snapshot: DecodingSnapshot
}

// MARK: - 获取属性初始值
extension DecodingCache {

    /// 恢复宿主属性声明时的完整包装器实例。
    ///
    /// 与 `initialValueIfPresent` 的 wrappedValue 兜底不同，这个接口保留包装器
    /// 自身的配置状态（例如 `SmartIgnored.isEncodable`），并且只读取精确匹配
    /// 宿主路径的快照，不从其他嵌套模型的同名属性猜测状态。
    func initialPropertyWrapperIfPresent<Wrapper: PropertyWrapperable>(
        forKey key: CodingKey?,
        codingPath: [CodingKey],
        as type: Wrapper.Type
    ) -> Wrapper? {
        guard let key = key else {
            return nil
        }

        guard let snapshot = activeSnapshot(at: codingPath) else {
            return nil
        }

        if snapshot.initialValues.isEmpty {
            populateInitialValues(snapshot: snapshot)
        }

        return snapshot.initialValues["_" + key.stringValue] as? Wrapper
    }
    /// 查找指定解码路径下容器中某个字段的初始值。
    ///
    /// 该方法会根据传入的 `codingPath`（代表某个解码容器的位置），
    /// 从当前活动 owner 获取 `key` 对应字段的初始值。
    /// 如果该 owner 尚未初始化初始值，则会延迟初始化一次（通过反射等方式）。
    func initialValueIfPresent<T>(forKey key: CodingKey?, codingPath: [CodingKey]) -> T? {
                
        guard let key = key else { return nil }

        guard let snapshot = activeSnapshot(at: codingPath) else { return nil }

        if snapshot.initialValues.isEmpty {
            populateInitialValues(snapshot: snapshot)
        }

        return initialValue(for: key, in: snapshot)
    }

    /// 从指定快照中读取字段初始值（支持属性包装器与枚举默认值）
    private func initialValue<T>(for key: CodingKey, in snapshot: DecodingSnapshot) -> T? {
        guard let cached = snapshot.initialValues[key.stringValue] else {
            return handlePropertyWrapperCases(for: key, snapshot: snapshot)
        }
        if let value = cached as? T {
            return value
        }
        if let caseValue = cached as? any SmartCaseDefaultable {
            return caseValue.rawValue as? T
        }
        return nil
    }
    
    func initialValue<T>(forKey key: CodingKey?, codingPath: [CodingKey]) throws -> T {
        guard let value: T = initialValueIfPresent(forKey: key, codingPath: codingPath) else {
            return try Patcher<T>.defaultForType()
        }
        return value
    }
}


// MARK: - 获取属性对应的值转换器
extension DecodingCache {
    
    /// 根据属性 key 和其所在容器路径，查找对应的值转换器（SmartValueTransformer）
    ///
    /// - Parameters:
    ///   - key: 当前正在解码的属性名（CodingKey），即字段名。可能为 `nil`，表示缺失或无法识别的字段。
    ///   - containerPath: 当前属性所在容器的完整路径（不含当前 key）。
    ///
    /// - Returns: 匹配到的 `SmartValueTransformer`，如果未找到则返回 `nil`。
    ///
    /// - Note:
    ///   - 此方法依赖于容器路径 `codingPath` 查找快照（snapshot），快照中包含该容器注册的所有转换器列表。
    ///   - 若 key 为 `nil` 或找不到快照，或快照中未注册转换器，均返回 `nil`。
    ///   - 转换器只从当前活动 owner 读取。
    func valueTransformer(for key: CodingKey?, in containerPath: [CodingKey]) -> SmartValueTransformer? {
        guard let lastKey = key else { return nil }

        return activeSnapshot(at: containerPath)?.transformers?.first(where: {
            $0.location.stringValue == lastKey.stringValue
        })
    }
}

extension DecodingCache {
    
    
    /// 处理属性包装器字段（以下划线 `_` 为前缀存储）的初始值提取
    private func handlePropertyWrapperCases<T>(for key: CodingKey, snapshot: DecodingSnapshot) -> T? {
        if let cached = snapshot.initialValues["_" + key.stringValue] {
            return extractWrappedValue(from: cached)
        }
        
        return nil
    }
    
    /// 从属性包装器实例中解包出实际的 wrappedValue
    private func extractWrappedValue<T>(from value: Any) -> T? {
        if let wrapper = value as? SmartIgnored<T> {
            return wrapper.wrappedValue
        } else if let wrapper = value as? SmartAny<T> {
            return wrapper.wrappedValue
        } else if let value = value as? T {
            return value
        }
        return nil
    }
    
    private func populateInitialValues(snapshot: DecodingSnapshot) {
        guard let type = snapshot.objectType else { return }
                
        // Recursively captures initial values from a type and its superclasses
        func captureInitialValues(from mirror: Mirror) {
            mirror.children.forEach { child in
                if let key = child.label {
                    snapshot.initialValues[key] = child.value
                }
            }
            if let superclassMirror = mirror.superclassMirror {
                captureInitialValues(from: superclassMirror)
            }
        }
        
        let mirror = Mirror(reflecting: type.init())
        captureInitialValues(from: mirror)
    }
}



/// 单个模型的解码状态快照
class DecodingSnapshot: Snapshot {
    typealias ObjectType = SmartDecodable.Type
    
    var objectType: (any SmartDecodable.Type)?
    
    var codingPath: [any CodingKey] = []

    /// 所属作用域的唯一标识
    var scopeIdentifier = 0
    
    lazy var transformers: [SmartValueTransformer]? = {
        objectType?.mappingForValue()
    }()
    
    /// 存储属性初始值的字典（Key: 属性名, Value: 初始值）
    var initialValues: [String : Any] = [:]
}
