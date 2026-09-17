import XCTest
@testable import SmartCodable

/// `DecodingCache.withSnapshot` 的生命周期契约测试
final class DecodingCacheLifecycleTests: XCTestCase {

    private var cache: DecodingCache!

    override func setUp() {
        super.setUp()
        cache = DecodingCache()
    }

    /// 符合资格的模型在 body 执行期间有一个快照，正常返回后恢复原栈深度
    func testEligibleModelHasSnapshotDuringBodyAndRestoresStackAfterReturn() {
        let before = cache.snapshots.count
        var duringBody = 0

        let result = cache.withSnapshot(for: LifecycleModel.self, codingPath: []) {
            duringBody = self.cache.snapshots.count
            return 42
        }

        XCTAssertEqual(result, 42)
        XCTAssertEqual(duringBody, before + 1)
        XCTAssertEqual(cache.snapshots.count, before)
    }

    /// body 抛错后仍恢复原栈深度
    func testThrowingBodyStillRestoresStackDepth() {
        let before = cache.snapshots.count

        XCTAssertThrowsError(try cache.withSnapshot(for: LifecycleModel.self, codingPath: []) {
            throw LifecycleTestError.boom
        })

        XCTAssertEqual(cache.snapshots.count, before)
    }

    /// 真实 unwrap 调用抛错后，也必须清理该调用创建的快照
    func testUnwrapThrowingModelRestoresSnapshotStack() {
        let smartDecoder = SmartJSONDecoder()
        let decoder = JSONDecoderImpl(
            userInfo: [:],
            from: .object([:]),
            codingPath: [],
            options: smartDecoder.options
        )

        XCTAssertThrowsError(try decoder.unwrap(as: ThrowingLifecycleModel.self))
        XCTAssertTrue(decoder.cache.snapshots.isEmpty)
    }

    /// 不符合资格的普通类型不改变栈
    func testIneligibleTypeDoesNotChangeStack() {
        let before = cache.snapshots.count
        var duringBody = before

        let result = cache.withSnapshot(for: String.self, codingPath: []) {
            duringBody = self.cache.snapshots.count
            return "ok"
        }

        XCTAssertEqual(result, "ok")
        XCTAssertEqual(duringBody, before)
        XCTAssertEqual(cache.snapshots.count, before)
    }

    /// 嵌套作用域内层抛错并被捕获后，外层快照仍是栈顶；外层结束后栈为空
    func testNestedThrowingScopeKeepsOuterSnapshotOnTopAndDrainsStack() throws {
        let outerResult = try cache.withSnapshot(
            for: LifecycleModel.self,
            codingPath: [LifecycleCodingKey.outer]
        ) {
            let outerSnapshot = try XCTUnwrap(self.cache.snapshots.last)
            let innerBefore = self.cache.snapshots.count

            XCTAssertThrowsError(
                try self.cache.withSnapshot(
                    for: LifecycleModel.self,
                    codingPath: [LifecycleCodingKey.outer, LifecycleCodingKey.inner]
                ) {
                    throw LifecycleTestError.boom
                }
            )

            XCTAssertEqual(self.cache.snapshots.count, innerBefore)
            XCTAssertEqual(self.cache.snapshots.count, 1)
            XCTAssertTrue(self.cache.snapshots.last === outerSnapshot)
            XCTAssertEqual(
                self.cache.snapshots.last?.codingPath.map(\.stringValue),
                [LifecycleCodingKey.outer.rawValue]
            )

            return "outer"
        }

        XCTAssertEqual(outerResult, "outer")
        XCTAssertTrue(cache.snapshots.isEmpty)
    }

    // MARK: - 快照栈深度不变量（每个活动中的模型 init 恰好持有一个快照）

    /// @SmartFlat（Optional 与非 Optional）解码内层模型期间，
    /// 快照栈深度必须恰好为“宿主 + 内层”两层：包装器自身不得额外压栈
    func testSmartFlatDecodingMaintainsHostPlusInnerSnapshotDepthOnly() throws {
        SnapshotDepthProbe.lastObservedDepth = nil
        _ = try XCTUnwrap(OptionalFlatProbeHost.deserialize(from: [:]))
        XCTAssertEqual(SnapshotDepthProbe.lastObservedDepth, 2,
                       "Optional 平铺期间应为 宿主+内层 两层快照，包装器不得重复压栈")

        SnapshotDepthProbe.lastObservedDepth = nil
        _ = try XCTUnwrap(NonOptionalFlatProbeHost.deserialize(from: [:]))
        XCTAssertEqual(SnapshotDepthProbe.lastObservedDepth, 2,
                       "非 Optional 平铺期间应为 宿主+内层 两层快照，包装器不得重复压栈")
    }

    /// 普通嵌套模型属性使用独立缓存，内层模型 init 期间栈深度为 1
    func testNestedModelPropertyDecodesWithIsolatedSnapshotStack() throws {
        SnapshotDepthProbe.lastObservedDepth = nil
        _ = try XCTUnwrap(NestedProbeHost.deserialize(from: ["user": [:]]))
        XCTAssertEqual(SnapshotDepthProbe.lastObservedDepth, 1)
    }

    // MARK: - createByDirectlyUnwrapping 逃逸通道（unwrapDictionary 场景）

    /// 字典值模型的解码必须经过 createByDirectlyUnwrapping 的快照作用域：
    /// 元素字段缺 key 时保留元素声明的默认值，而不是退化为类型零值
    func testDictionaryValuedModelsPreserveElementDefaultsThroughDirectUnwrap() throws {
        struct Host: SmartCodableX {
            var slots: [String: DictEntry] = [:]
        }

        let host = try XCTUnwrap(Host.deserialize(from: [
            "slots": ["a": ["name": "A"], "b": [:]]
        ]))

        XCTAssertEqual(host.slots["a"]?.name, "A")
        XCTAssertEqual(host.slots["b"]?.name, "inner-default",
                       "字典元素缺 key 时应命中元素自身快照的声明默认值")
    }

    // MARK: - SmartAny 模型兜底路径

    /// @SmartAny 包装模型时，兜底解码路径同样要建立快照作用域，保留模型声明默认值
    func testSmartAnyModelBackedValueKeepsDeclaredDefaultsWhenKeysMissing() throws {
        struct Model: SmartCodableX {
            @SmartAny var payload: SmartAnyTargetModel = .init()
        }

        let model = try XCTUnwrap(Model.deserialize(from: ["payload": [:]]))

        XCTAssertEqual(model.payload.score, 11)
    }

    // MARK: - SmartIgnored 无 parsingMark 路径

    /// 未设置 parsingMark 时（第三方直接触发解码），@SmartIgnored 应取宿主声明的初始值，
    /// 而不是退化为 Patcher 的全新默认实例
    func testSmartIgnoredWithoutParsingMarkKeepsHostDeclaredInitialValue() throws {
        let smartDecoder = SmartJSONDecoder()
        let impl = JSONDecoderImpl(
            userInfo: [:],
            from: .object(["settings": .object(["level": .number("999")])]),
            codingPath: [],
            options: smartDecoder.options
        )

        let host = try impl.unwrap(as: MarklessHost.self)

        XCTAssertEqual(host.settings.level, 7,
                       "应保留宿主声明的初始值 7，而非 JSON 的 999 或 Patcher 的 0")
    }
}

private final class LifecycleModel: SmartCodableX {
    var value: String = ""
    required init() {}
}

private final class ThrowingLifecycleModel: SmartCodableX {
    required init() {}

    required init(from decoder: Decoder) throws {
        throw LifecycleTestError.boom
    }
}

private enum LifecycleTestError: Error {
    case boom
}

private enum LifecycleCodingKey: String, CodingKey {
    case outer
    case inner
}

/// 在 init(from:) 内记录当时快照栈深度的探针模型
private final class SnapshotDepthProbe: SmartCodableX {
    static var lastObservedDepth: Int?

    required init() {}

    required init(from decoder: Decoder) throws {
        if let impl = decoder as? JSONDecoderImpl {
            Self.lastObservedDepth = impl.cache.snapshots.count
        }
    }
}

private struct OptionalFlatProbeHost: SmartCodableX {
    @SmartFlat var user: SnapshotDepthProbe?
}

private struct NonOptionalFlatProbeHost: SmartCodableX {
    @SmartFlat var user: SnapshotDepthProbe = SnapshotDepthProbe()
}

private struct NestedProbeHost: SmartCodableX {
    var user: SnapshotDepthProbe?
}

/// 字典值元素模型（默认值与类型零值不同，用于断言敏感度）
private struct DictEntry: SmartCodableX {
    var name: String = "inner-default"
}

/// @SmartAny 兜底解码的目标模型
private struct SmartAnyTargetModel: SmartCodableX {
    var score: Int = 11
}

/// 无 parsingMark 场景的宿主：声明初始值与 init() 默认值不同，用于区分取值来源
private final class MarklessHost: SmartCodableX {
    @SmartIgnored var settings: MarklessSettings = .init(level: 7)
    required init() {}
}

private struct MarklessSettings: SmartCodableX {
    var level: Int = 0

    init() {}
    init(level: Int) {
        self.level = level
    }
}
