import Foundation
@testable import SmartCodable

/// 测试工具：递归深度比较 Any 类型（字典/数组/基础值/NSNull）
enum TestSupport {
    /// 任意值深度比较（处理 NSNumber/NSNull 等桥接类型）
    static func deepEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        switch (lhs, rhs) {
        case let (a as Int, b as Int): return a == b
        case let (a as Double, b as Double): return a == b
        case let (a as String, b as String): return a == b
        case let (a as Bool, b as Bool): return a == b
        case let (a as [String: Any], b as [String: Any]):
            return deepEqualDict(a, b)
        case let (a as [Any], b as [Any]):
            return deepEqualArray(a, b)
        case let (a as NSNumber, b as NSNumber):
            return a == b
        case (is NSNull, is NSNull):
            return true
        default:
            return false
        }
    }

    /// 字典深度比较：键集合一致 + 每个值递归相等
    static func deepEqualDict(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for (key, lValue) in lhs {
            guard let rValue = rhs[key], deepEqual(lValue, rValue) else {
                return false
            }
        }
        return true
    }

    /// 数组深度比较：长度一致 + 逐元素递归
    static func deepEqualArray(_ lhs: [Any], _ rhs: [Any]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy(deepEqual)
    }
}

/// 基础测试模型：可选 String/Int/枚举
struct BasicModel: SmartCodableX {
    var name: String?
    var age: Int?
    var sex: Sex?

    enum Sex: Int, SmartCaseDefaultable {
        case man = 1
        case women = 0
    }
}

/// 带CodingKey映射的嵌套模型：模拟真实API响应结构（snake_case → camelCase）
struct WorkspaceModel: SmartCodableX {
    var id: Int = 0
    var ownerId: Int = 0
    var title: String = ""
    var icon: String = ""
    var type: Int = 0
    var usedSeat: Int = 0
    var createdAt: String = ""
    var subscription: WorkspaceSubscription?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId
        case title
        case icon
        case type
        case usedSeat
        case createdAt
        case subscription
    }

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [
            CodingKeys.ownerId <--- "owner_id",
            CodingKeys.usedSeat <--- "used_seat",
            CodingKeys.createdAt <--- "created_at",
        ]
    }
}

/// 订阅子模型：独立 CodingKey 映射
struct WorkspaceSubscription: SmartCodableX {
    var cancelAtPeriodEnd: Bool = false
    var currentPeriodEndAt: String = ""
    var priceId: String = ""
    var status: String = ""

    enum CodingKeys: String, CodingKey {
        case cancelAtPeriodEnd
        case currentPeriodEndAt
        case priceId
        case status
    }

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [
            CodingKeys.cancelAtPeriodEnd <--- "cancel_at_period_end",
            CodingKeys.currentPeriodEndAt <--- "current_period_end_at",
            CodingKeys.priceId <--- "price_id",
        ]
    }
}

/// 无键数组模型：测试 decodeIfPresent 在数组中的行为
struct UnkeyedStringArrayModel: SmartCodableX {
    var values: [String?] = []
}

/// 数值策略模型：测试 truncate/rounded 等策略
struct NumberStrategyModel: SmartCodableX {
    var value: Int = 99
}

/// @SmartAny 空值模型：测试 NSNull 捕获能力
struct SmartAnyNullModel: SmartCodableX {
    @SmartAny var any: Any? = "default"
}
