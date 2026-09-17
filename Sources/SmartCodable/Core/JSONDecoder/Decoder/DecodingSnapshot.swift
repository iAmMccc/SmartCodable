//
//  DecodingSnapshot.swift
//  SmartCodable
//
//  解码上下文显式绑定：某一次模型解码的默认值与映射上下文。
//

import Foundation

/// 某一次模型解码的默认值及映射上下文。
///
/// 每个新的、框架可观察的 Smart 模型初始化入口都会创建自己的实例：
/// snapshot 只服务这一次 `init(from:)`，其中的反射默认值与值转换器缓存
/// 不与其他初始化调用共享，也不按类型、路径或作用域去重。
/// `objectType` 在构造后不可修改。
final class DecodingSnapshot {

    /// 该上下文归属的模型类型（构造后不可变）
    let objectType: any SmartDecodable.Type

    /// nil 表示尚未反射；[:] 表示已经反射且没有存储字段。
    private var cachedInitialValues: [String: Any]?

    private lazy var cachedTransformers: [SmartValueTransformer]? = {
        objectType.mappingForValue()
    }()

    init(objectType: any SmartDecodable.Type) {
        self.objectType = objectType
    }

    func transformer(forKey key: any CodingKey) -> SmartValueTransformer? {
        cachedTransformers?.first {
            $0.location.stringValue == key.stringValue
        }
    }

    private func initialValues() -> [String: Any] {
        if let cachedInitialValues {
            return cachedInitialValues
        }
        var values: [String: Any] = [:]
        func capture(_ mirror: Mirror) {
            for child in mirror.children {
                if let label = child.label {
                    values[label] = child.value
                }
            }
            if let superclass = mirror.superclassMirror {
                capture(superclass)
            }
        }
        capture(Mirror(reflecting: objectType.init()))
        cachedInitialValues = values
        return values
    }
}

extension DecodingSnapshot {

    /// 供模型容器读取本模型某字段的默认值（返回的 T 可能本身就是包装器）。
    ///
    /// 查询顺序与解码侧旧实现的 initialValueIfPresent 一致：
    /// 普通存储名优先（含 SmartCaseDefaultable rawValue 转换），
    /// 未命中再查 `_` 前缀的包装器存储并解包 wrappedValue。
    /// 仅访问当前对象的字段表，不从其他模型上下文兜底。
    func initialValueIfPresent<T>(forKey key: any CodingKey) -> T? {
        let values = initialValues()
        if let cached = values[key.stringValue] {
            if let value = cached as? T {
                return value
            }
            if let caseValue = cached as? any SmartCaseDefaultable {
                return caseValue.rawValue as? T
            }
            return nil
        }
        guard let cached = values["_" + key.stringValue] else {
            return nil
        }
        return extractWrappedValue(from: cached)
    }

    /// 带类型兜底的默认值读取（找不到声明默认值时走 Patcher）
    func initialValue<T>(forKey key: any CodingKey) throws -> T {
        if let value: T = initialValueIfPresent(forKey: key) {
            return value
        }
        return try Patcher<T>.defaultForType()
    }

    /// 供宿主属性上下文恢复精确类型的完整包装器声明。
    ///
    /// 必须返回包装器自身的实例（保留如 `SmartIgnored.isEncodable` 的配置），
    /// 不能只取 `wrappedValue` 再重新构造包装器。
    func declaredWrapper<W: PropertyWrapperable>(
        forKey key: any CodingKey,
        as type: W.Type
    ) -> W? {
        initialValues()["_" + key.stringValue] as? W
    }

    private func extractWrappedValue<T>(from value: Any) -> T? {
        if let wrapper = value as? SmartIgnored<T> {
            return wrapper.wrappedValue
        }
        if let wrapper = value as? SmartAny<T> {
            return wrapper.wrappedValue
        }
        return value as? T
    }
}

/// 宿主某一条属性的解码上下文。
///
/// 只记录“声明该属性的宿主模型上下文”与“该属性的规范 CodingKey”这一条边，
/// 不提供向父级链式搜索的能力；一次属性处理结束后，
/// 其子字段必须以子模型为宿主重新建立自己的属性上下文。
struct PropertyDecodingContext {
    let owner: DecodingSnapshot
    let key: any CodingKey

    func declaredWrapper<W: PropertyWrapperable>(as type: W.Type) -> W? {
        owner.declaredWrapper(forKey: key, as: type)
    }

    func transformer() -> SmartValueTransformer? {
        owner.transformer(forKey: key)
    }
}
