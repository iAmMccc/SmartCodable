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

    // MARK: - 第三方属性包装器的模型快照作用域

    /// 第三方包装器直接调用 `Value(from:)` 时，内层 SmartDecodable 仍应拥有自己的快照，
    /// 并与通过 SingleValueDecodingContainer 重新进入 unwrap 的包装器保持一致。
    func testThirdPartyWrappersPreserveWrappedModelDefaultsWithoutDuplicateSnapshots() throws {
        WrapperProbeModel.lastObservedDepth = nil
        let direct = try XCTUnwrap(DirectWrapperHost.deserialize(from: ["payload": [:]]))

        XCTAssertEqual(direct.payload.count, 99)
        XCTAssertEqual(WrapperProbeModel.lastObservedDepth, 2,
                       "直接初始化路径应只有宿主与内层模型两个活动快照")

        WrapperProbeModel.lastObservedDepth = nil
        let container = try XCTUnwrap(ContainerWrapperHost.deserialize(from: ["payload": [:]]))

        XCTAssertEqual(container.payload.count, 99)
        XCTAssertEqual(WrapperProbeModel.lastObservedDepth, 2,
                       "容器解码路径不应为同一个内层模型重复建立快照")
    }

    /// 双协议包装器与内层模型共享 codingPath 时，两者都必须保留各自声明的默认值。
    func testDualConformingWrapperPreservesWrapperAndWrappedModelDefaults() throws {
        let direct = try XCTUnwrap(DualDirectWrapperHost.deserialize(from: ["payload": [:]]))
        XCTAssertEqual(direct.payload.count, 99)
        XCTAssertEqual(direct.$payload.marker, 7)
    }

    /// 包装器自己的 key/value mapping 必须归属于包装器 owner，不能被同路径的内层模型覆盖。
    func testDualConformingWrapperKeepsItsOwnKeyAndValueMappings() throws {
        let host = try XCTUnwrap(DualDirectWrapperHost.deserialize(from: [
            "payload": [
                "wrapper_marker": "41",
                "wrapped_count": "2"
            ]
        ]))

        XCTAssertEqual(host.$payload.marker, 42)
        XCTAssertEqual(host.payload.count, 102)
    }

    /// 同名、无 mapping 的字段也必须按 CodingKeys owner 归属，不能固定取 owner 组末尾。
    func testDualConformingWrapperAndWrappedModelKeepSameNamedDefaults() throws {
        let direct = try XCTUnwrap(SameNameDirectHost.deserialize(from: ["payload": [:]]))
        XCTAssertEqual(direct.$payload.shared, 7)
        XCTAssertEqual(direct.payload.shared, 99)

        let container = try XCTUnwrap(SameNameContainerHost.deserialize(from: ["payload": [:]]))
        XCTAssertEqual(container.$payload.shared, 7)
        XCTAssertEqual(container.payload.shared, 99)

        let innerFirst = try XCTUnwrap(SameNameInnerFirstHost.deserialize(from: ["payload": [:]]))
        XCTAssertEqual(innerFirst.$payload.shared, 7)
        XCTAssertEqual(innerFirst.payload.shared, 99)
    }

    /// 旧 wrapper 没有 owner transition 时保持确定性的 wrapper-first 兼容语义。
    func testLegacyDualWrapperWithoutOwnerTransitionUsesWrapperOwner() throws {
        let host = try XCTUnwrap(LegacySameNameHost.deserialize(from: ["payload": [:]]))

        XCTAssertEqual(host.$payload.shared, 7)
        XCTAssertEqual(host.payload.shared, 7)
    }

    /// 无 parsingMark 时，完整属性包装器恢复也必须使用当前活动的 wrapper owner。
    func testDualOwnerRestoresCompleteNestedPropertyWrapperFromWrapperOwner() throws {
        let smartDecoder = SmartJSONDecoder()
        let impl = JSONDecoderImpl(
            userInfo: [:],
            from: .object(["settings": .object([:])]),
            codingPath: [],
            options: smartDecoder.options
        )

        let wrapper = try impl.unwrap(as: DualIgnoredOwnerWrapper.self)

        XCTAssertEqual(wrapper.settings.level, 7)
        XCTAssertTrue(wrapper.settingsIsEncodable)
        XCTAssertEqual(wrapper.wrappedValue.shared, 99)
        XCTAssertTrue(impl.cache.snapshots.isEmpty)
    }

    /// 双层双协议 wrapper 必须在同一 scope 内逐级提升预声明 owner，不能重复创建内层 wrapper 快照。
    func testNestedDualWrappersReusePredeclaredOwnersForDirectAndContainerDecoding() throws {
        NestedDualLeaf.resetObservations()
        let defaults = try XCTUnwrap(NestedDirectWrapperHost.deserialize(from: ["payload": [:]]))

        XCTAssertEqual(defaults.$payload.outerMarker, 11)
        XCTAssertEqual(defaults.$payload.wrappedValue.innerMarker, 22)
        XCTAssertEqual(defaults.payload.value, 99)
        assertNestedDualSnapshotObservations()
        XCTAssertTrue(try XCTUnwrap(NestedDualLeaf.observedCache).snapshots.isEmpty)
        XCTAssertEqual(try XCTUnwrap(NestedDualLeaf.observedCache).activeOwnerDepth, 0)

        NestedDualLeaf.resetObservations()
        let direct = try XCTUnwrap(NestedDirectWrapperHost.deserialize(from: [
            "payload": [
                "outer_marker": "40",
                "inner_marker": "50"
            ]
        ]))

        XCTAssertEqual(direct.$payload.outerMarker, 41)
        XCTAssertEqual(direct.$payload.wrappedValue.innerMarker, 52)
        XCTAssertEqual(direct.payload.value, 99)
        assertNestedDualSnapshotObservations()
        XCTAssertTrue(try XCTUnwrap(NestedDualLeaf.observedCache).snapshots.isEmpty)
        XCTAssertEqual(try XCTUnwrap(NestedDualLeaf.observedCache).activeOwnerDepth, 0)

        NestedDualLeaf.resetObservations()
        let container = try XCTUnwrap(NestedContainerWrapperHost.deserialize(from: [
            "payload": [
                "outer_marker": "40",
                "inner_marker": "50"
            ]
        ]))

        XCTAssertEqual(container.$payload.outerMarker, 41)
        XCTAssertEqual(container.$payload.wrappedValue.innerMarker, 52)
        XCTAssertEqual(container.payload.value, 99)
        assertNestedDualSnapshotObservations()
        XCTAssertTrue(try XCTUnwrap(NestedDualLeaf.observedCache).snapshots.isEmpty)
        XCTAssertEqual(try XCTUnwrap(NestedDualLeaf.observedCache).activeOwnerDepth, 0)
    }

    /// 双层 owner transition 的最内层抛错时，本次 entry 创建的所有 owner 都必须按逆序清理。
    func testThrowingNestedDualWrappersDrainSnapshotsAndRestoreHostDefaults() throws {
        ThrowingNestedDualLeaf.resetObservations()

        let host = try XCTUnwrap(ThrowingNestedWrapperHost.deserialize(from: [
            "payload": [:],
            "trailing": "not-an-int"
        ]))

        XCTAssertEqual(host.$payload.outerMarker, 11)
        XCTAssertEqual(host.$payload.wrappedValue.innerMarker, 22)
        XCTAssertEqual(host.payload.value, 99)
        XCTAssertEqual(host.trailing, 77)
        XCTAssertEqual(ThrowingNestedDualLeaf.observedSnapshotDepth, 3)
        XCTAssertEqual(ThrowingNestedDualLeaf.observedActiveOwnerDepth, 3)
        XCTAssertTrue(try XCTUnwrap(ThrowingNestedDualLeaf.observedCache).snapshots.isEmpty)
        XCTAssertEqual(try XCTUnwrap(ThrowingNestedDualLeaf.observedCache).activeOwnerDepth, 0)
    }

    private func assertNestedDualSnapshotObservations(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(NestedDualLeaf.observedSnapshotDepth, 3, file: file, line: line)
        XCTAssertEqual(NestedDualLeaf.observedActiveOwnerDepth, 3, file: file, line: line)
        XCTAssertEqual(NestedDualLeaf.observedObjectTypeCount, 3, file: file, line: line)
        XCTAssertEqual(NestedDualLeaf.observedScopeCount, 1, file: file, line: line)
    }

    /// 第三方包装器的内层模型抛错时，包装器提供的快照必须随作用域清理；
    /// 宿主应回退到声明值，并继续恢复后续字段的声明默认值。
    func testThrowingThirdPartyWrapperRestoresSnapshotStackAndHostDefaults() throws {
        ThrowingWrapperProbeModel.observedCache = nil

        let legacyHost = try XCTUnwrap(ThrowingWrapperHost.deserialize(from: [
            "payload": [:],
            "trailing": "not-an-int"
        ]))

        XCTAssertEqual(legacyHost.payload.marker, 41)
        XCTAssertEqual(legacyHost.trailing, 77)
        XCTAssertTrue(try XCTUnwrap(ThrowingWrapperProbeModel.observedCache).snapshots.isEmpty)

        ThrowingWrapperProbeModel.observedCache = nil
        let dualHost = try XCTUnwrap(ThrowingDualWrapperHost.deserialize(from: [
            "payload": [:],
            "trailing": "not-an-int"
        ]))

        XCTAssertEqual(dualHost.payload.marker, 41)
        XCTAssertEqual(dualHost.$payload.marker, 7)
        XCTAssertEqual(dualHost.trailing, 77)
        XCTAssertTrue(try XCTUnwrap(ThrowingWrapperProbeModel.observedCache).snapshots.isEmpty)
    }

    /// 包装器通过 singleValueContainer 重入内层模型后即使抛错，也必须清空该作用域，
    /// 并让宿主后续字段继续命中宿主声明的默认值。
    func testThrowingContainerWrapperReentryCleansSnapshotsAndRestoresHostDefaults() throws {
        ThrowingWrapperProbeModel.observedCache = nil

        let host = try XCTUnwrap(ThrowingContainerWrapperHost.deserialize(from: [
            "payload": [:],
            "trailing": "not-an-int"
        ]))

        XCTAssertEqual(host.payload.marker, 41)
        XCTAssertEqual(host.trailing, 77)
        XCTAssertTrue(try XCTUnwrap(ThrowingWrapperProbeModel.observedCache).snapshots.isEmpty)
    }

    // MARK: - SmartIgnored 无 parsingMark 路径

    func testSentinelUsesExecutingWrapperAndWrappedOwner() throws {
        let previousMode = SmartSentinel.debugMode
        SmartSentinel.debugMode = .verbose
        defer {
            SmartSentinel.debugMode = previousMode
            SmartSentinel.onLogGenerated { _ in }
        }

        for (payload, expectedOwner) in [
            (["wrapped_count": "2"], "DualDirectInitWrapper<DualWrapperProbeModel>"),
            (["wrapper_marker": "bad", "wrapped_count": "2"], "DualDirectInitWrapper<DualWrapperProbeModel>"),
            (["wrapper_marker": "41"], "DualWrapperProbeModel")
        ] {
            let logged = expectation(description: expectedOwner)
            SmartSentinel.onLogGenerated { message in
                XCTAssertTrue(message.contains("payload: " + expectedOwner + "\n"), message)
                logged.fulfill()
            }
            _ = try XCTUnwrap(DualDirectWrapperHost.deserialize(from: ["payload": payload]))
            wait(for: [logged], timeout: 1)
        }
    }

    func testActiveOwnerRestoresAfterWrappedReturnAndThrow() throws {
        typealias Wrapper = DualDirectInitWrapper<DualWrapperProbeModel>
        try cache.withSnapshot(for: Wrapper.self, codingPath: []) {
            XCTAssertTrue(self.cache.activeOwner(at: []) == Wrapper.self)
            self.cache.withSnapshot(for: DualWrapperProbeModel.self, codingPath: []) {
                XCTAssertTrue(self.cache.activeOwner(at: []) == DualWrapperProbeModel.self)
                XCTAssertEqual(self.cache.snapshots.count, 2)
            }
            XCTAssertTrue(self.cache.activeOwner(at: []) == Wrapper.self)
            XCTAssertThrowsError(try self.cache.withSnapshot(for: DualWrapperProbeModel.self, codingPath: []) {
                XCTAssertTrue(self.cache.activeOwner(at: []) == DualWrapperProbeModel.self)
                throw LifecycleTestError.boom
            })
            XCTAssertTrue(self.cache.activeOwner(at: []) == Wrapper.self)
        }
        XCTAssertNil(cache.activeOwner(at: []))
        XCTAssertEqual(cache.activeOwnerDepth, 0)
        XCTAssertTrue(cache.snapshots.isEmpty)
    }

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

private protocol ModelWrapper: PropertyWrapperable, Codable
where WrappedValue: SmartDecodable & SmartEncodable {}

private extension ModelWrapper {
    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }

    static func createInstance(with value: Any) -> Self? {
        guard let value = value as? WrappedValue else { return nil }
        return Self(wrappedValue: value)
    }

    func wrappedValueDidFinishMapping() -> Self? {
        var value = wrappedValue
        value.didFinishMapping()
        return Self(wrappedValue: value)
    }
}

@propertyWrapper
private struct DirectInitWrapper<Value: SmartDecodable & SmartEncodable>: ModelWrapper {
    var wrappedValue: Value

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        wrappedValue = try Value(from: decoder)
    }

}

@propertyWrapper
private struct ContainerDecodeWrapper<Value: SmartDecodable & SmartEncodable>: ModelWrapper {
    var wrappedValue: Value

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(Value.self)
    }

}

@propertyWrapper
private struct DualDirectInitWrapper<Value: SmartDecodable & SmartEncodable>: ModelWrapper, SmartCodableX {
    var wrappedValue: Value
    var marker: Int = 7

    var projectedValue: Self { self }

    private enum CodingKeys: String, CodingKey {
        case marker
    }

    init() {
        wrappedValue = Value()
    }

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        marker = try container.decode(Int.self, forKey: .marker)
        wrappedValue = try Self.decodeWrappedValue(from: decoder)
    }

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [CodingKeys.marker <--- "wrapper_marker"]
    }

    static func mappingForValue() -> [SmartValueTransformer]? {
        [
            CodingKeys.marker <--- FastTransformer<Int, String>(fromJSON: { value in
                value.flatMap(Int.init).map { $0 + 1 }
            })
        ]
    }

}

private struct DirectWrapperHost: SmartCodableX {
    @DirectInitWrapper var payload = WrapperProbeModel()
}

private struct ContainerWrapperHost: SmartCodableX {
    @ContainerDecodeWrapper var payload = WrapperProbeModel()
}

private struct DualDirectWrapperHost: SmartCodableX {
    @DualDirectInitWrapper var payload = DualWrapperProbeModel()
}

private enum NestedOuterWrapperKeys: String, CodingKey {
    case outerMarker
}

private enum NestedInnerWrapperKeys: String, CodingKey {
    case innerMarker
}

@propertyWrapper
private struct NestedOuterWrapper<Value: SmartDecodable & SmartEncodable>: ModelWrapper, SmartCodableX {
    var wrappedValue: Value
    var outerMarker = 11

    var projectedValue: Self { self }

    init() {
        wrappedValue = Value()
    }

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NestedOuterWrapperKeys.self)
        outerMarker = try container.decode(Int.self, forKey: .outerMarker)
        wrappedValue = try Self.decodeWrappedValue(from: decoder)
    }

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [NestedOuterWrapperKeys.outerMarker <--- "outer_marker"]
    }

    static func mappingForValue() -> [SmartValueTransformer]? {
        [
            NestedOuterWrapperKeys.outerMarker <--- FastTransformer<Int, String>(fromJSON: { value in
                value.flatMap(Int.init).map { $0 + 1 }
            })
        ]
    }
}

@propertyWrapper
private struct NestedDirectInnerWrapper<Value: SmartDecodable & SmartEncodable>: ModelWrapper, SmartCodableX {
    var wrappedValue: Value
    var innerMarker = 22

    var projectedValue: Self { self }

    init() {
        wrappedValue = Value()
    }

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NestedInnerWrapperKeys.self)
        innerMarker = try container.decode(Int.self, forKey: .innerMarker)
        wrappedValue = try Self.decodeWrappedValue(from: decoder)
    }

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [NestedInnerWrapperKeys.innerMarker <--- "inner_marker"]
    }

    static func mappingForValue() -> [SmartValueTransformer]? {
        [
            NestedInnerWrapperKeys.innerMarker <--- FastTransformer<Int, String>(fromJSON: { value in
                value.flatMap(Int.init).map { $0 + 2 }
            })
        ]
    }
}

@propertyWrapper
private struct NestedContainerInnerWrapper<Value: SmartDecodable & SmartEncodable>: ModelWrapper, SmartCodableX {
    var wrappedValue: Value
    var innerMarker = 22

    var projectedValue: Self { self }

    init() {
        wrappedValue = Value()
    }

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let keyed = try decoder.container(keyedBy: NestedInnerWrapperKeys.self)
        innerMarker = try keyed.decode(Int.self, forKey: .innerMarker)
        let single = try decoder.singleValueContainer()
        wrappedValue = try single.decode(Value.self)
    }

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [NestedInnerWrapperKeys.innerMarker <--- "inner_marker"]
    }

    static func mappingForValue() -> [SmartValueTransformer]? {
        [
            NestedInnerWrapperKeys.innerMarker <--- FastTransformer<Int, String>(fromJSON: { value in
                value.flatMap(Int.init).map { $0 + 2 }
            })
        ]
    }
}

private struct NestedDirectWrapperHost: SmartCodableX {
    @NestedOuterWrapper @NestedDirectInnerWrapper var payload = NestedDualLeaf()
}

private struct NestedContainerWrapperHost: SmartCodableX {
    @NestedOuterWrapper @NestedContainerInnerWrapper var payload = NestedDualLeaf()
}

private struct ThrowingNestedWrapperHost: SmartCodableX {
    @NestedOuterWrapper @NestedDirectInnerWrapper var payload = ThrowingNestedDualLeaf()
    var trailing = 77
}

private struct ThrowingWrapperHost: SmartCodableX {
    @DirectInitWrapper var payload = ThrowingWrapperProbeModel()
    var trailing: Int = 77
}

private struct ThrowingContainerWrapperHost: SmartCodableX {
    @ContainerDecodeWrapper var payload = ThrowingWrapperProbeModel()
    var trailing: Int = 77
}

private struct ThrowingDualWrapperHost: SmartCodableX {
    @DualDirectInitWrapper var payload = ThrowingWrapperProbeModel()
    var trailing: Int = 77
}

@propertyWrapper
private struct SameNameDirectWrapper<Value: SmartDecodable & SmartEncodable>: ModelWrapper, SmartCodableX {
    var wrappedValue: Value
    var shared: Int = 7

    var projectedValue: Self { self }

    init() {
        wrappedValue = Value()
    }

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SharedOwnerKeys.self)
        shared = try container.decode(Int.self, forKey: .shared)
        wrappedValue = try Self.decodeWrappedValue(from: decoder)
    }

}

@propertyWrapper
private struct SameNameContainerWrapper<Value: SmartDecodable & SmartEncodable>: ModelWrapper, SmartCodableX {
    var wrappedValue: Value
    var shared: Int = 7

    var projectedValue: Self { self }

    init() {
        wrappedValue = Value()
    }

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let keyed = try decoder.container(keyedBy: SharedOwnerKeys.self)
        shared = try keyed.decode(Int.self, forKey: .shared)
        let single = try decoder.singleValueContainer()
        wrappedValue = try single.decode(Value.self)
    }

}

private struct SameNameDirectHost: SmartCodableX {
    @SameNameDirectWrapper var payload = SameNameModel()
}

private struct SameNameContainerHost: SmartCodableX {
    @SameNameContainerWrapper var payload = SameNameModel()
}

@propertyWrapper
private struct SameNameInnerFirstWrapper<Value: SmartDecodable & SmartEncodable>: ModelWrapper, SmartCodableX {
    var wrappedValue: Value
    var shared: Int = 7

    var projectedValue: Self { self }

    init() {
        wrappedValue = Value()
    }

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        wrappedValue = try Self.decodeWrappedValue(from: decoder)
        let container = try decoder.container(keyedBy: SharedOwnerKeys.self)
        shared = try container.decode(Int.self, forKey: .shared)
    }

}

private struct SameNameInnerFirstHost: SmartCodableX {
    @SameNameInnerFirstWrapper var payload = SameNameModel()
}

@propertyWrapper
private struct LegacySameNameWrapper<Value: SmartDecodable & SmartEncodable>: ModelWrapper, SmartCodableX {
    var wrappedValue: Value
    var shared: Int = 7
    var projectedValue: Self { self }

    init() { wrappedValue = Value() }
    init(wrappedValue: Value) { self.wrappedValue = wrappedValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SharedOwnerKeys.self)
        shared = try container.decode(Int.self, forKey: .shared)
        wrappedValue = try Value(from: decoder)
    }
}

private struct LegacySameNameHost: SmartCodableX {
    @LegacySameNameWrapper var payload = SameNameModel()
}

private struct SameNameModel: SmartCodableX {
    var shared: Int = 99

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SharedOwnerKeys.self)
        shared = try container.decode(Int.self, forKey: .shared)
    }
}

private enum SharedOwnerKeys: String, CodingKey {
    case shared
}

@propertyWrapper
private struct DualIgnoredOwnerWrapper: PropertyWrapperable, SmartCodableX {
    var wrappedValue = SameNameModel()

    @SmartIgnored(wrappedValue: DualIgnoredSettings(level: 7), isEncodable: true)
    var settings: DualIgnoredSettings

    var settingsIsEncodable: Bool { _settings.isEncodable }

    private enum CodingKeys: String, CodingKey {
        case settings
    }

    init() {}

    init(wrappedValue: SameNameModel) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _settings = try container.decode(
            SmartIgnored<DualIgnoredSettings>.self,
            forKey: .settings
        )
        wrappedValue = try Self.decodeWrappedValue(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }

    static func createInstance(with value: Any) -> Self? {
        guard let value = value as? SameNameModel else { return nil }
        return Self(wrappedValue: value)
    }

    func wrappedValueDidFinishMapping() -> Self? { self }
}

private struct DualIgnoredSettings: SmartCodableX {
    var level: Int = 0

    init() {}

    init(level: Int) {
        self.level = level
    }
}

private struct WrapperProbeModel: SmartCodableX {
    static var lastObservedDepth: Int?
    var count: Int = 99

    init() {}

    init(from decoder: Decoder) throws {
        Self.lastObservedDepth = (decoder as? JSONDecoderImpl)?.cache.snapshots.count
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decode(Int.self, forKey: .count)
    }
}

private struct ThrowingWrapperProbeModel: SmartCodableX {
    static var observedCache: DecodingCache?
    var marker: Int = 41

    init() {}

    init(from decoder: Decoder) throws {
        Self.observedCache = (decoder as? JSONDecoderImpl)?.cache
        throw LifecycleTestError.boom
    }
}

private struct DualWrapperProbeModel: SmartCodableX {
    var count: Int = 99

    private enum CodingKeys: String, CodingKey {
        case count
    }

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [CodingKeys.count <--- "wrapped_count"]
    }

    static func mappingForValue() -> [SmartValueTransformer]? {
        [
            CodingKeys.count <--- FastTransformer<Int, String>(fromJSON: { value in
                value.flatMap(Int.init).map { $0 + 100 }
            })
        ]
    }
}

private struct NestedDualLeaf: SmartCodableX {
    static var observedCache: DecodingCache?
    static var observedSnapshotDepth: Int?
    static var observedActiveOwnerDepth: Int?
    static var observedObjectTypeCount: Int?
    static var observedScopeCount: Int?

    var value = 99

    init() {}

    init(from decoder: Decoder) throws {
        if let cache = (decoder as? JSONDecoderImpl)?.cache {
            Self.observedCache = cache
            Self.observedSnapshotDepth = cache.snapshots.count
            Self.observedActiveOwnerDepth = cache.activeOwnerDepth
            Self.observedObjectTypeCount = Set(
                cache.snapshots.compactMap(\.objectType).map(ObjectIdentifier.init)
            ).count
            Self.observedScopeCount = Set(cache.snapshots.map(\.scopeIdentifier)).count
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(Int.self, forKey: .value)
    }

    static func resetObservations() {
        observedCache = nil
        observedSnapshotDepth = nil
        observedActiveOwnerDepth = nil
        observedObjectTypeCount = nil
        observedScopeCount = nil
    }
}

private struct ThrowingNestedDualLeaf: SmartCodableX {
    static var observedCache: DecodingCache?
    static var observedSnapshotDepth: Int?
    static var observedActiveOwnerDepth: Int?

    var value = 99

    init() {}

    init(from decoder: Decoder) throws {
        if let cache = (decoder as? JSONDecoderImpl)?.cache {
            Self.observedCache = cache
            Self.observedSnapshotDepth = cache.snapshots.count
            Self.observedActiveOwnerDepth = cache.activeOwnerDepth
        }
        throw LifecycleTestError.boom
    }

    static func resetObservations() {
        observedCache = nil
        observedSnapshotDepth = nil
        observedActiveOwnerDepth = nil
    }
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
