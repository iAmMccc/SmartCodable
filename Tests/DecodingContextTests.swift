import XCTest
#if canImport(Combine)
import Combine
#endif
// ColorObject 在 UIKit 平台是 UIColor、macOS 是 NSColor；按平台声明测试所需的颜色框架
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import SmartCodable

/// 解码上下文（DecodingSnapshot / PropertyDecodingContext）的契约测试。
///
/// 由旧 `DecodingCacheLifecycleTests` 迁移：保留全部行为断言（默认值、映射、
/// 包装器配置、异常后宿主字段、编码输出），把 snapshots.count / activeOwnerDepth /
/// scopeIdentifier 等旧状态机白盒探针替换为“容器固定绑定正确 owner”的语义断言。
final class DecodingContextTests: XCTestCase {

    // MARK: - 上下文对象单元契约

    /// 同一个 snapshot 内的懒加载默认值只反射一次，重复查询复用同一份引用
    func testSameSnapshotReusesLazilyCapturedDefaultReference() throws {
        ContextBoxModel.mirrorInitCount = 0
        let snapshot = DecodingSnapshot(objectType: ContextBoxModel.self)

        let first: ContextBox = try XCTUnwrap(snapshot.initialValueIfPresent(forKey: ContextKeys.box))
        let second: ContextBox = try XCTUnwrap(snapshot.initialValueIfPresent(forKey: ContextKeys.box))

        XCTAssertTrue(first === second)
        XCTAssertEqual(ContextBoxModel.mirrorInitCount, 1,
                       "同一 snapshot 内重复查询不应重新执行 objectType.init()")
    }

    /// 不同 snapshot 是两次独立构造，默认值对象不得意外别名
    func testDistinctSnapshotsProvideIndependentDefaultObjects() throws {
        let snapshotA = DecodingSnapshot(objectType: ContextBoxModel.self)
        let snapshotB = DecodingSnapshot(objectType: ContextBoxModel.self)

        let boxA: ContextBox = try XCTUnwrap(snapshotA.initialValueIfPresent(forKey: ContextKeys.box))
        let boxB: ContextBox = try XCTUnwrap(snapshotB.initialValueIfPresent(forKey: ContextKeys.box))

        XCTAssertFalse(boxA === boxB)
        XCTAssertEqual(boxA.value, 10)
        XCTAssertEqual(boxB.value, 10)
    }

    /// declaredWrapper 返回完整包装器声明，保留自身配置（isEncodable），而非仅 wrappedValue
    func testDeclaredWrapperPreservesWrapperConfiguration() throws {
        let snapshot = DecodingSnapshot(objectType: ContextIgnoredHost.self)

        let declared: SmartIgnored<ContextIgnoredSettings> = try XCTUnwrap(
            snapshot.declaredWrapper(forKey: ContextKeys.settings, as: SmartIgnored<ContextIgnoredSettings>.self)
        )

        XCTAssertTrue(declared.isEncodable)
        XCTAssertEqual(declared.wrappedValue.level, 7)
    }

    /// “已反射且没有存储字段”与“尚未反射”必须可区分：空表只执行一次 provider
    func testEmptyFieldTableIsLoadedExactlyOnce() throws {
        ContextEmptyModel.providerCount = 0
        let snapshot = DecodingSnapshot(objectType: ContextEmptyModel.self)

        let missing: ContextBox? = snapshot.initialValueIfPresent(forKey: ContextKeys.box)
        XCTAssertNil(missing)
        let stillMissing: ContextBox? = snapshot.initialValueIfPresent(forKey: ContextKeys.box)
        XCTAssertNil(stillMissing)

        XCTAssertEqual(ContextEmptyModel.providerCount, 1,
                       "已加载的空表不应被误判成未加载而反复执行 provider")
    }

    /// transformer 查询命中当前模型声明的转换器，未声明的 key 返回 nil
    func testTransformerLookupIsScopedToOwningModel() throws {
        let snapshot = DecodingSnapshot(objectType: ContextMappedModel.self)
        let transformer = try XCTUnwrap(snapshot.transformer(forKey: ContextKeys.name))
        let decoded = try XCTUnwrap(transformer.transformFromJSON(.string("mccc")) as? String)
        XCTAssertEqual(decoded, "MCCC")
        XCTAssertNil(snapshot.transformer(forKey: ContextKeys.other))
    }

    // MARK: - 容器固定绑定（替代旧快照栈深度断言）

    /// @SmartFlat 内层模型解码期间，内层容器必须绑定内层模型，宿主容器不被替换
    func testSmartFlatInnerContainerBindsInnerModelOwner() throws {
        OwnerProbeModel.reset()
        _ = try XCTUnwrap(FlatProbeHost.deserialize(from: [:]))
        XCTAssertEqual(OwnerProbeModel.observedOwnerTypeName, "OwnerProbeModel",
                       "平铺内层模型的容器必须绑定内层模型自己的上下文")
    }

    /// 普通嵌套模型属性解码期间，模型绑定自身（不再依赖共享栈）
    func testNestedModelPropertyContainerBindsNestedModelOwner() throws {
        OwnerProbeModel.reset()
        _ = try XCTUnwrap(NestedProbeHost.deserialize(from: ["user": [:]]))
        XCTAssertEqual(OwnerProbeModel.observedOwnerTypeName, "OwnerProbeModel")
    }

    /// unwrap 抛错后不得残留影响后续解码的状态：下一次解码仍取得正确默认值
    func testUnwrapThrowingModelLeavesNoResidualStateForNextDecode() throws {
        let smartDecoder = SmartJSONDecoder()
        let impl = JSONDecoderImpl(
            userInfo: [:],
            from: .object([:]),
            codingPath: [],
            options: smartDecoder.options
        )

        XCTAssertThrowsError(try impl.unwrap(as: ThrowingLifecycleModel.self))

        let next = try impl.unwrap(as: ContextBoxModel.self)
        XCTAssertEqual(next.box.value, 10,
                       "上一次抛错的解码不得影响下一次入口的默认值")
    }

    // MARK: - 独立调用与稳定归属

    /// 同一次模型 init 内多次请求 keyed / single 容器：从两个容器读取同一缺失字段，
    /// 复用本次初始化的同一个引用类型默认对象，且默认值 provider 只执行一次（T32）
    func testRepeatedContainerRequestsKeepSameContextInOneInit() throws {
        RepeatedContainerHost.resetDefaultProviderCallCount()

        let model = try XCTUnwrap(RepeatedContainerHost.deserialize(from: [:]))

        XCTAssertTrue(model.firstBox === model.secondBox,
                      "同一次 init 内两个容器读取同一缺失字段，应取得同一个默认对象")
        XCTAssertEqual(model.firstBox?.value, 10,
                       "默认对象内容应来自宿主声明的初始值")
        XCTAssertEqual(RepeatedContainerHost.defaultProviderCallCount, 1,
                       "默认值 provider（objectType.init() 反射构造）在同一次初始化内只执行一次")
    }

    /// 不同宿主的同名 _settings 声明只能恢复属性边精确指向的那一个（T33）
    func testPropertyEdgeRestoresPreciseHostDeclaration() throws {
        let host = try XCTUnwrap(EdgeParentHost.deserialize(from: ["child": [:]]))

        XCTAssertEqual(host.settings.level, 7)
        XCTAssertFalse(host.settingsIsEncodable)
        XCTAssertEqual(host.child.settings.level, 9)
        XCTAssertTrue(host.child.settingsIsEncodable)
    }

    /// 用户在 init 中主动引用静态单例属于用户指定的共享，框架不得擅自深拷贝（T35）
    func testStaticSingletonDefaultIsNotCopied() throws {
        let first = try XCTUnwrap(SingletonDefaultModel.deserialize(from: [:]))
        let second = try XCTUnwrap(SingletonDefaultModel.deserialize(from: [:]))

        XCTAssertTrue(first.box === SingletonBox.shared)
        XCTAssertTrue(second.box === SingletonBox.shared)
    }

    // MARK: - 字典值直接解包与 SmartAny 兜底

    /// 字典值元素缺 key 时保留元素声明的默认值，而不是退化为类型零值
    func testDictionaryValuedModelsPreserveElementDefaultsThroughDirectUnwrap() throws {
        struct Host: SmartCodableX {
            var slots: [String: DictEntry] = [:]
        }

        let host = try XCTUnwrap(Host.deserialize(from: [
            "slots": ["a": ["name": "A"], "b": [:]]
        ]))

        XCTAssertEqual(host.slots["a"]?.name, "A")
        XCTAssertEqual(host.slots["b"]?.name, "inner-default",
                       "字典元素缺 key 时应命中元素自身上下文的声明默认值")
    }

    /// @SmartAny 包装模型时，兜底解码路径保留模型声明默认值
    func testSmartAnyModelBackedValueKeepsDeclaredDefaultsWhenKeysMissing() throws {
        struct Model: SmartCodableX {
            @SmartAny var payload: SmartAnyTargetModel = .init()
        }

        let model = try XCTUnwrap(Model.deserialize(from: ["payload": [:]]))

        XCTAssertEqual(model.payload.score, 11)
    }

    // MARK: - 第三方包装器与双协议包装器

    /// 第三方包装器两条路径（直接初始化与 single-value 重入）都保留内层声明默认值
    func testThirdPartyWrappersPreserveWrappedModelDefaults() throws {
        let direct = try XCTUnwrap(DirectWrapperHost.deserialize(from: ["payload": [:]]))
        XCTAssertEqual(direct.payload.count, 99)

        let container = try XCTUnwrap(ContainerWrapperHost.deserialize(from: ["payload": [:]]))
        XCTAssertEqual(container.payload.count, 99)
    }

    /// 双协议包装器与内层模型共享 codingPath 时，两者都保留各自声明的默认值
    func testDualConformingWrapperPreservesWrapperAndWrappedModelDefaults() throws {
        let direct = try XCTUnwrap(DualDirectWrapperHost.deserialize(from: ["payload": [:]]))
        XCTAssertEqual(direct.payload.count, 99)
        XCTAssertEqual(direct.$payload.marker, 7)
    }

    /// 包装器自己的 key/value mapping 归属包装器 owner，不被同路径内层模型覆盖
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

    /// 同名、无 mapping 的字段按各自 CodingKeys owner 归属，不依赖解码顺序
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

    /// 旧 wrapper 未使用协作入口时保持确定性的 wrapper-first 兼容语义
    func testLegacyDualWrapperWithoutOwnerTransitionUsesWrapperOwner() throws {
        let host = try XCTUnwrap(LegacySameNameHost.deserialize(from: ["payload": [:]]))

        XCTAssertEqual(host.$payload.shared, 7)
        XCTAssertEqual(host.payload.shared, 7)
    }

    /// 无 parsingMark 时，嵌套包装器内的完整属性包装器声明从包装器自己的属性表恢复
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
    }

    /// 双层双协议 wrapper：逐级建立自己的上下文，直接初始化与容器路径一致
    func testNestedDualWrappersKeepPerLevelOwnersForDirectAndContainerDecoding() throws {
        NestedDualLeaf.resetObservations()
        let defaults = try XCTUnwrap(NestedDirectWrapperHost.deserialize(from: ["payload": [:]]))

        XCTAssertEqual(defaults.$payload.outerMarker, 11)
        XCTAssertEqual(defaults.$payload.wrappedValue.innerMarker, 22)
        XCTAssertEqual(defaults.payload.value, 99)
        XCTAssertEqual(NestedDualLeaf.observedOwnerTypeName, "NestedDualLeaf")

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
        XCTAssertEqual(NestedDualLeaf.observedOwnerTypeName, "NestedDualLeaf")

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
        XCTAssertEqual(NestedDualLeaf.observedOwnerTypeName, "NestedDualLeaf")
    }

    // MARK: - 异常路径

    /// 双层 wrapper 最内层抛错时无需任何恢复动作，宿主回退声明值并继续后续字段
    func testThrowingNestedDualWrappersRestoreHostDefaults() throws {
        ThrowingNestedDualLeaf.resetObservations()

        let host = try XCTUnwrap(ThrowingNestedWrapperHost.deserialize(from: [
            "payload": [:],
            "trailing": "not-an-int"
        ]))

        XCTAssertEqual(host.$payload.outerMarker, 11)
        XCTAssertEqual(host.$payload.wrappedValue.innerMarker, 22)
        XCTAssertEqual(host.payload.value, 99)
        XCTAssertEqual(host.trailing, 77)
    }

    /// 第三方包装器内层抛错：宿主取得声明回退，后续字段继续命中宿主默认值
    func testThrowingThirdPartyWrapperRestoresHostDefaults() throws {
        let legacyHost = try XCTUnwrap(ThrowingWrapperHost.deserialize(from: [
            "payload": [:],
            "trailing": "not-an-int"
        ]))

        XCTAssertEqual(legacyHost.payload.marker, 41)
        XCTAssertEqual(legacyHost.trailing, 77)

        let dualHost = try XCTUnwrap(ThrowingDualWrapperHost.deserialize(from: [
            "payload": [:],
            "trailing": "not-an-int"
        ]))

        XCTAssertEqual(dualHost.payload.marker, 41)
        XCTAssertEqual(dualHost.$payload.marker, 7)
        XCTAssertEqual(dualHost.trailing, 77)
    }

    /// 包装器经 singleValueContainer 重入后抛错：宿主后续字段继续命中声明默认值
    func testThrowingContainerWrapperReentryRestoresHostDefaults() throws {
        let host = try XCTUnwrap(ThrowingContainerWrapperHost.deserialize(from: [
            "payload": [:],
            "trailing": "not-an-int"
        ]))

        XCTAssertEqual(host.payload.marker, 41)
        XCTAssertEqual(host.trailing, 77)
    }

    // MARK: - 日志归属

    /// 哨兵日志的模型名来自容器固定所属模型，与解码顺序无关
    func testSentinelLogsContainerOwningModel() throws {
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

    // MARK: - SmartIgnored 无 parsingMark 路径

    /// 未设置 parsingMark 时，@SmartIgnored 取宿主声明的初始值，而非 Patcher 全新实例
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

    // MARK: - 集合与结构下钻

    /// 根数组与嵌套数组中的 Smart 模型每个元素独立取得默认值（T38）
    func testRootAndNestedArraysGiveElementsIndependentDefaults() throws {
        let roots = try XCTUnwrap([ArrayElementChild].deserialize(from: [
            ["tag": "a"],
            [:] as [String: Any]
        ]))
        XCTAssertEqual(roots.map(\.tag), ["a", "inner"])

        let host = try XCTUnwrap(ArrayElementHost.deserialize(from: [
            "models": [[:], ["tag": "b"]] as [Any]
        ]))
        XCTAssertEqual(host.models.map(\.tag), ["inner", "b"])
    }

    /// 宿主字段整体 transformer 只对整个字段生效一次，不泄漏到内部元素（T39）
    func testWholeFieldTransformerAppliesOncePerField() throws {
        CountingListTransformer.applyCount = 0
        let host = try XCTUnwrap(TransformerListHost.deserialize(from: [
            "scores": ["1", "2"]
        ]))

        XCTAssertEqual(host.scores, [11, 12])
        XCTAssertEqual(CountingListTransformer.applyCount, 1,
                       "整字段 transformer 应在字段层生效一次，而不是逐元素生效")
    }

    /// JSON 字符串形式的对象输入同样绑定正确的容器上下文（T41）
    func testJSONStringObjectInputBindsContainerContext() throws {
        let model = try XCTUnwrap(StringInputHost.deserialize(from: "{\"name\":\"mccc\"}"))
        XCTAssertEqual(model.name, "mccc")
        XCTAssertEqual(model.mikeNo, "我是默认值")
    }

    /// 手写 nestedContainer 取得的原始子结构不继承宿主字段表（T45/T12）
    func testHandWrittenNestedContainerStaysIsolated() throws {
        let host = try XCTUnwrap(RawNestedHost.deserialize(from: [
            "plain": [:] as [String: Any]
        ]))

        XCTAssertEqual(host.count, 99, "宿主自己的字段仍取宿主声明默认值")
        XCTAssertEqual(host.plainCount, 0, "原始嵌套结构不得借用宿主字段表")
    }

    // MARK: - 回调次数

    /// didFinishMapping 在各完成节点恰好执行一次（T46）
    func testDidFinishMappingExecutesExactlyOncePerCompletionPoint() throws {
        MappingCountedModel.mappingCount = 0
        _ = try XCTUnwrap(MappingCountedModel.deserialize(from: [:]))
        XCTAssertEqual(MappingCountedModel.mappingCount, 1, "根模型入口")

        MappingCountedModel.mappingCount = 0
        _ = try XCTUnwrap(MappingCountHost.deserialize(from: ["child": [:]]))
        XCTAssertEqual(MappingCountedModel.mappingCount, 1, "普通嵌套属性")

        MappingCountedModel.mappingCount = 0
        _ = try XCTUnwrap(MappingCountHost.deserialize(from: [:]))
        XCTAssertEqual(MappingCountedModel.mappingCount, 1, "缺失字段回退后的嵌套属性")

        MappingCountedModel.mappingCount = 0
        _ = try XCTUnwrap(MappingCountArrayHost.deserialize(from: [
            "items": [[:], [:]] as [Any]
        ]))
        XCTAssertEqual(MappingCountedModel.mappingCount, 2, "数组元素各一次")

        MappingCountedModel.mappingCount = 0
        let transformed = try XCTUnwrap(MappingTransformerHost.deserialize(from: [
            "child": "5"
        ]))
        XCTAssertEqual(transformed.child.level, 5, "必须真的走了 transformer 转换路径")
        XCTAssertEqual(MappingCountedModel.mappingCount, 1, "transformer 返回值路径")
    }

    // MARK: - 并发解码

    /// 多个独立 decoder 并发解码：空输入真实触发默认值回退，
    /// 不同模型的默认上下文互不串扰，跨调用不共享可变默认对象（T49）。
    /// 结果全部保留存活后再比较对象身份，避免对象释放后的地址复用干扰判断。
    /// 数据竞争检测配合 TSan：
    /// swift test --sanitize=thread --filter DecodingContextTests.testConcurrentIndependentDecodersFallbackDefaultsStayIsolated
    func testConcurrentIndependentDecodersFallbackDefaultsStayIsolated() throws {
        final class ConcurrentRefBox: Codable {
            // var + 初值：合成的 Decodable 可以解码该属性（本用例中键缺失，保持初值 10），
            // 避免对 let+初值属性产生 "immutable property will not be decoded" 告警
            var stamp = 10
        }

        final class ConcurrentDefaultAlpha: SmartCodableX {
            var tag = "alpha"
            var box = ConcurrentRefBox()
            required init() {}
        }

        final class ConcurrentDefaultBeta: SmartCodableX {
            var tag = "beta"
            required init() {}
        }

        let iterations = 80
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "smartcodable.tests.decode", attributes: .concurrent)
        let lock = NSLock()
        var alphaModels: [ConcurrentDefaultAlpha] = []
        var betaModels: [ConcurrentDefaultBeta] = []

        for index in 0..<iterations {
            group.enter()
            queue.async {
                defer { group.leave() }
                // 空字典：字段全部缺失，每次解码都真实走 snapshot 默认值回退路径
                if index.isMultiple(of: 2) {
                    let decoded = ConcurrentDefaultAlpha.deserialize(from: [:] as [String: Any])
                    lock.lock()
                    if let decoded { alphaModels.append(decoded) }
                    lock.unlock()
                } else {
                    let decoded = ConcurrentDefaultBeta.deserialize(from: [:] as [String: Any])
                    lock.lock()
                    if let decoded { betaModels.append(decoded) }
                    lock.unlock()
                }
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 10), .success)

        XCTAssertEqual(alphaModels.count, iterations / 2)
        XCTAssertEqual(betaModels.count, iterations / 2)
        XCTAssertTrue(alphaModels.allSatisfy { $0.tag == "alpha" },
                      "并发下 alpha 默认值不得丢失或串成 beta")
        XCTAssertTrue(betaModels.allSatisfy { $0.tag == "beta" },
                      "并发下 beta 默认值不得串成 alpha")

        let boxIds = Set(alphaModels.map { ObjectIdentifier($0.box) })
        XCTAssertEqual(boxIds.count, alphaModels.count,
                       "每次独立解码的引用类型默认对象必须独立，不得跨调用共享")
        XCTAssertTrue(alphaModels.allSatisfy { $0.box.stamp == 10 },
                      "默认对象内容保持声明初始值")
    }

    // MARK: - 第三方包装器 Optional 内层

    /// 第三方包装器包装 Optional 内层模型：直接初始化路径仍保留内层声明默认值（T14）
    func testOptionalThirdPartyWrapperKeepsWrappedModelDefaults() throws {
        let present = try XCTUnwrap(OptionalWrapperHost.deserialize(from: ["payload": [:]]))
        XCTAssertEqual(present.payload?.count, 99, "直接初始化路径内层默认值可用")

        let missing = try XCTUnwrap(OptionalWrapperHost.deserialize(from: [:]))
        XCTAssertEqual(missing.payload?.count, 99, "字段缺失时恢复宿主声明的完整包装器默认值")
    }

    // MARK: - SmartAny 组合回退

    /// @SmartAny 包装 Optional 模型：缺字段与错误类型都回退声明默认值（T25）
    func testSmartAnyOptionalModelFallsBackToDeclaredDefaults() throws {
        struct OptionalHost: SmartCodableX {
            @SmartAny var payload: SmartAnyTargetModel? = SmartAnyTargetModel()
        }

        let missing = try XCTUnwrap(OptionalHost.deserialize(from: ["other": 1]))
        XCTAssertEqual(missing.payload?.score, 11, "缺字段回退宿主声明默认值")

        let wrongType = try XCTUnwrap(OptionalHost.deserialize(from: ["payload": 123]))
        XCTAssertEqual(wrongType.payload?.score, 11, "错误类型回退声明默认值，不产生半解码模型")
    }

    /// @SmartAny 非 Optional 模型遇到错误类型：回退声明默认值（T25）
    func testSmartAnyNonOptionalModelWrongTypeFallsBackToDeclaredDefault() throws {
        struct Host: SmartCodableX {
            @SmartAny var payload: SmartAnyTargetModel = SmartAnyTargetModel()
        }

        let host = try XCTUnwrap(Host.deserialize(from: ["payload": "text"]))
        XCTAssertEqual(host.payload.score, 11)
    }

    // MARK: - SmartPublished

    /// @SmartPublished：内层默认值、数据与发布行为保持正常（T26）
    #if canImport(Combine)
    func testSmartPublishedKeepsDefaultsDataAndPublishing() throws {
        struct Host: SmartCodableX {
            @SmartPublished var score: Int = 7
            @SmartPublished var child: PublishedChild = PublishedChild()
        }

        var decoded = try XCTUnwrap(Host.deserialize(from: [
            "score": 42,
            "child": ["level": 33]
        ]))
        XCTAssertEqual(decoded.score, 42)
        XCTAssertEqual(decoded.child.level, 33)

        let fallback = try XCTUnwrap(Host.deserialize(from: [:]))
        XCTAssertEqual(fallback.score, 7, "缺字段保留声明默认值")
        XCTAssertEqual(fallback.child.level, 11, "内层模型默认值生效")

        var received: [Int] = []
        let cancellable = decoded.$score.sink { received.append($0) }
        XCTAssertEqual(received, [42], "CurrentValueSubject 订阅即收到当前值")
        decoded.score = 50
        XCTAssertEqual(received, [42, 50], "wrappedValue willSet 触发发布")
        withExtendedLifetime(cancellable) {}
    }
    #endif

    // MARK: - JSON 字符串数组输入

    /// JSON 字符串形式的数组值：unkeyedContainer 的字符串解析分支同样取得正确上下文（T41）
    func testJSONStringArrayInputBindsElementContexts() throws {
        let host = try XCTUnwrap(StringArrayInputHost.deserialize(from: [
            "models": "[{\"tag\":\"a\"},{\"tag\":\"b\"},{}]"
        ]))

        XCTAssertEqual(host.models.map(\.tag), ["a", "b", "inner"],
                       "字符串数组元素各自解码并取得自己的默认值")
    }

    // MARK: - 特殊类型与数值边界

    /// Date / Data / URL / Decimal / CGFloat 特殊分支与 Int64/UInt64 边界、Int8 溢出回退（T42）
    func testSpecialTypeUnwrapAndNumericBoundaries() throws {
        struct Host: SmartCodableX {
            var date: Date = Date(timeIntervalSince1970: 0)
            var data: Data? = nil
            var url: URL? = nil
            var decimal: Decimal? = nil
            var cgfloat: CGFloat = 0
            var bigInt64: Int64 = 0
            var bigUInt64: UInt64 = 0
            var smallInt8: Int8 = 7
        }

        let host = try XCTUnwrap(Host.deserialize(from: [
            "date": 1_753_413_115,
            "data": "SGVsbG8=",
            "url": "https://example.com/x",
            "decimal": 0.1,
            "cgfloat": 2.5,
            "bigInt64": Int64.max,
            "bigUInt64": NSNumber(value: UInt64.max),
            "smallInt8": 300,
        ] as [String: Any]))

        XCTAssertEqual(host.date.timeIntervalSince1970, 1_753_413_115, accuracy: 0.001,
                       "秒级时间戳经 DateParser 兜底解析")
        XCTAssertEqual(host.data, Data(base64Encoded: "SGVsbG8="))
        XCTAssertEqual(host.url?.absoluteString, "https://example.com/x")
        XCTAssertEqual(host.decimal, Decimal(string: "0.1"))
        XCTAssertEqual(host.cgfloat, 2.5)
        XCTAssertEqual(host.bigInt64, Int64.max, "Int64 上边界无损")
        XCTAssertEqual(host.bigUInt64, UInt64.max, "UInt64 上边界无损")
        XCTAssertEqual(host.smallInt8, 7, "溢出输入回退声明默认值，不截断成错误值")
    }

    // MARK: - 继承的映射与转换器

    /// 手写父子类共享 decoder：组合声明的 Key Mapping 与 Value Transformer
    /// 在同一次子类解码中同时生效（T44）
    func testInheritanceKeepsDeclaredKeyMappingAndValueTransformer() throws {
        let base = try XCTUnwrap(MappedBaseModel.deserialize(from: ["base_value": "5"]))
        XCTAssertEqual(base.baseValue, 105, "父类单独入口应用父类声明的映射与 transformer")

        let derived = try XCTUnwrap(MappedDerivedModel.deserialize(from: [
            "base_value": "5",
            "child_value": "3",
        ]))
        XCTAssertEqual(derived.baseValue, 105,
                       "同一次子类解码中，父类声明的映射与 transformer 仍然生效")
        XCTAssertEqual(derived.childValue, 203,
                       "同一次子类解码中，子类声明的映射与 transformer 同时生效")

        let encoded = try XCTUnwrap(derived.toDictionary())
        XCTAssertEqual(encoded["baseValue"] as? Int, 105)
        XCTAssertEqual(encoded["childValue"] as? Int, 203)
    }

    // MARK: - superDecoder 隔离

    /// 手写 superDecoder 取得的视图不继承宿主字段表（T45）
    func testHandWrittenSuperDecoderStaysIsolated() throws {
        let host = try XCTUnwrap(SuperDecoderHost.deserialize(from: [
            "plain": [:] as [String: Any]
        ]))

        XCTAssertEqual(host.count, 99, "宿主自己的字段仍取宿主声明默认值")
        XCTAssertEqual(host.plainCount, 0, "superDecoder 视图不得借用宿主字段表")
    }

    // MARK: - 包装器回调次数

    /// 包装器路径 wrappedValueDidFinishMapping 恰好执行一次：解码成功、缺字段回退、transformer（T46）
    func testWrapperDidFinishMappingExecutesExactlyOnce() throws {
        WrapperCountedModel.mappingCount = 0
        _ = try XCTUnwrap(WrapperCountHost.deserialize(from: ["payload": [:]]))
        XCTAssertEqual(WrapperCountedModel.mappingCount, 1, "包装器解码成功路径")

        WrapperCountedModel.mappingCount = 0
        _ = try XCTUnwrap(WrapperCountHost.deserialize(from: [:]))
        XCTAssertEqual(WrapperCountedModel.mappingCount, 1, "包装器缺字段回退路径")

        WrapperCountedModel.mappingCount = 0
        let transformed = try XCTUnwrap(WrapperTransformerHost.deserialize(from: ["payload": "5"]))
        XCTAssertEqual(transformed.payload.level, 5, "必须真的走了 transformer 转换路径")
        XCTAssertEqual(WrapperCountedModel.mappingCount, 1, "包装器 transformer 路径不得双重通知")
    }

    // MARK: - SmartHexColor 配置与编码

    /// SmartHexColor：声明非默认 encodeHexFormat，解码按 JSON，编码仍用声明格式（T24/T48）。
    /// 分量断言不经过 deviceRGB 色域转换，避免设备色域影响数值稳定性。
    func testSmartHexColorKeepsDeclaredEncodeFormatAcrossRoundTrip() throws {
        struct Host: SmartCodableX {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbb(.hash))
            var hashed: ColorObject?

            @SmartHexColor(wrappedValue: nil)
            var plain: ColorObject?
        }

        let host = try XCTUnwrap(Host.deserialize(from: [
            "hashed": "#FF0000",
            "plain": "00FF00",
        ]))

        // 预期颜色由平台颜色 API 独立构造，不依赖被测试的 SmartHexColor 解析函数
#if os(macOS)
        let expectedHashed = NSColor(calibratedRed: 1, green: 0, blue: 0, alpha: 1)
        let expectedPlain = NSColor(calibratedRed: 0, green: 1, blue: 0, alpha: 1)
#else
        let expectedHashed = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        let expectedPlain = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
#endif

        XCTAssertEqual(host.hashed, expectedHashed,
                       "颜色值按 JSON 解码，不被声明默认覆盖")
        XCTAssertEqual(host.plain, expectedPlain)

        let encoded = try XCTUnwrap(host.toDictionary())
        let hashedHex = try XCTUnwrap(encoded["hashed"] as? String)
        XCTAssertEqual(hashedHex.first, "#", "编码使用属性边恢复的声明 hash 前缀格式")
        XCTAssertEqual(hashedHex.count, 7, "声明 rrggbb(.hash) 应输出带前缀的 6 位色值")
        XCTAssertEqual(hashedHex.dropFirst().count, 6)

        let plainHex = try XCTUnwrap(encoded["plain"] as? String)
        XCTAssertNotEqual(plainHex.first, "#", "未声明格式时使用默认 rrggbb(.none)")
        XCTAssertEqual(plainHex.count, 6)
    }

    // MARK: - 上下文释放

    /// 正常解码结束后，框架不再持有本次解码的模型上下文（T47 弱引用探针）
    func testDecoderContextIsReleasedAfterDecodeCompletes() throws {
        final class ReleaseProbe: SmartCodableX {
            static weak var observedContext: DecodingSnapshot?

            var value = 1

            required init() {}
            required init(from decoder: Decoder) throws {
                ReleaseProbe.observedContext = (decoder as? JSONDecoderImpl)?.modelSnapshot
            }
        }

        var result: ReleaseProbe?
        autoreleasepool {
            result = ReleaseProbe.deserialize(from: [:] as [String: Any])
        }

        XCTAssertNotNil(result)
        XCTAssertNil(ReleaseProbe.observedContext,
                     "解码完成后框架不应继续持有模型上下文（引用环或全局注册都会导致此断言失败）")
    }
}

// MARK: - 单元契约 fixture

private enum ContextKeys: String, CodingKey {
    case box
    case settings
    case name
    case other
}

private final class ContextBox: Codable {
    var value = 10
}

private final class ContextBoxModel: SmartCodableX {
    static var mirrorInitCount = 0

    var box = ContextBox()

    required init() {
        ContextBoxModel.mirrorInitCount += 1
    }
}

private struct ContextIgnoredHost: SmartCodableX {
    @SmartIgnored(wrappedValue: ContextIgnoredSettings(level: 7), isEncodable: true)
    var settings: ContextIgnoredSettings
}

private struct ContextIgnoredSettings: SmartCodableX {
    var level: Int = 0

    init() {}
    init(level: Int) {
        self.level = level
    }
}

/// 没有存储字段的模型：用于验证空表与未加载的区分
private final class ContextEmptyModel: SmartDecodable, SmartEncodable {
    static var providerCount = 0

    required init() {
        ContextEmptyModel.providerCount += 1
    }
}

private struct ContextMappedModel: SmartCodableX {
    var name: String = ""
    var other: String = ""

    static func mappingForValue() -> [SmartValueTransformer]? {
        [ContextKeys.name <--- ContextUpperTransformer()]
    }
}

private struct ContextUpperTransformer: ValueTransformable {
    typealias Object = String
    typealias JSON = String

    func transformFromJSON(_ value: Any) -> String? {
        (value as? String)?.uppercased()
    }

    func transformToJSON(_ value: String) -> String? {
        value
    }
}

// MARK: - 容器归属探针

private final class OwnerProbeModel: SmartCodableX {
    static var observedOwnerTypeName: String?

    static func reset() {
        observedOwnerTypeName = nil
    }

    required init() {}
    required init(from decoder: Decoder) throws {
        if let impl = decoder as? JSONDecoderImpl {
            OwnerProbeModel.observedOwnerTypeName = impl.modelSnapshot.map { String(describing: $0.objectType) }
        }
    }
}

private struct FlatProbeHost: SmartCodableX {
    @SmartFlat var user: OwnerProbeModel?
}

private struct NestedProbeHost: SmartCodableX {
    var user: OwnerProbeModel?
}

private final class ThrowingLifecycleModel: SmartCodableX {
    required init() {}

    required init(from decoder: Decoder) throws {
        throw ContextTestError.boom
    }
}

private enum ContextTestError: Error {
    case boom
}

// MARK: - 独立调用与归属 fixture

/// 重复容器请求用例的引用类型默认值。
/// 遵循 Codable 只为满足 decode(_:forKey:) 的约束；键缺失时不会触发其自身解码。
private final class RepeatedContainerBox: Codable {
    var value = 10
}

private struct RepeatedContainerHost: SmartCodableX {
    private(set) static var defaultProviderCallCount = 0

    private enum CodingKeys: String, CodingKey { case box }

    /// 声明的引用类型默认属性：只应由默认值反射构造一次
    var box = RepeatedContainerBox()

    /// 同一次 init(from:) 中两个容器分别读取同一缺失字段的结果，供测试断言身份
    var firstBox: RepeatedContainerBox?
    var secondBox: RepeatedContainerBox?

    static func resetDefaultProviderCallCount() {
        defaultProviderCallCount = 0
    }

    /// DecodingSnapshot 通过 objectType.init() 获取声明默认值时调用；
    /// init(from:) 的属性初始化不会进入此计数。
    init() {
        Self.defaultProviderCallCount += 1
    }
    init(from decoder: Decoder) throws {
        let first = try decoder.container(keyedBy: CodingKeys.self)
        _ = try decoder.singleValueContainer()
        let second = try decoder.container(keyedBy: CodingKeys.self)
        _ = try decoder.singleValueContainer()

        // 键缺失，真实走默认值回退：两个容器分别读取同一个字段
        firstBox = try first.decode(RepeatedContainerBox.self, forKey: .box)
        secondBox = try second.decode(RepeatedContainerBox.self, forKey: .box)
    }

    func encode(to encoder: Encoder) throws {}
}

private struct EdgeSettings: SmartCodableX {
    var level: Int = 0

    init() {}
    init(level: Int) {
        self.level = level
    }
}

private struct EdgeChild: SmartCodableX {
    @SmartIgnored(wrappedValue: EdgeSettings(level: 9), isEncodable: true)
    var settings: EdgeSettings

    var settingsIsEncodable: Bool { _settings.isEncodable }
}

private struct EdgeParentHost: SmartCodableX {
    @SmartIgnored(wrappedValue: EdgeSettings(level: 7), isEncodable: false)
    var settings: EdgeSettings

    var child = EdgeChild()

    var settingsIsEncodable: Bool { _settings.isEncodable }
}

private final class SingletonBox: Codable {
    static let shared = SingletonBox()
    var value = 5
    private init() {}
}

private struct SingletonDefaultModel: SmartCodableX {
    var box = SingletonBox.shared
}

// MARK: - 字典与 SmartAny fixture

/// 字典值元素模型（默认值与类型零值不同，用于断言敏感度）
private struct DictEntry: SmartCodableX {
    var name: String = "inner-default"
}

/// @SmartAny 兜底解码的目标模型
private struct SmartAnyTargetModel: SmartCodableX {
    var score: Int = 11
}

// MARK: - 包装器 fixture（自旧 DecodingCacheLifecycleTests 迁移）

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
    var count: Int = 99

    private enum CodingKeys: String, CodingKey {
        case count
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decode(Int.self, forKey: .count)
    }
}

private struct ThrowingWrapperProbeModel: SmartCodableX {
    var marker: Int = 41

    init() {}

    init(from decoder: Decoder) throws {
        throw ContextTestError.boom
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
    static var observedOwnerTypeName: String?

    var value = 99

    private enum CodingKeys: String, CodingKey {
        case value
    }

    init() {}

    init(from decoder: Decoder) throws {
        if let impl = decoder as? JSONDecoderImpl {
            NestedDualLeaf.observedOwnerTypeName = impl.modelSnapshot.map { String(describing: $0.objectType) }
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(Int.self, forKey: .value)
    }

    static func resetObservations() {
        observedOwnerTypeName = nil
    }
}

private struct ThrowingNestedDualLeaf: SmartCodableX {
    var value = 99

    init() {}

    init(from decoder: Decoder) throws {
        throw ContextTestError.boom
    }

    static func resetObservations() {}
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

// MARK: - 集合与结构下钻 fixture

private struct ArrayElementChild: SmartCodableX {
    var tag: String = "inner"
}

private struct ArrayElementHost: SmartCodableX {
    var models: [ArrayElementChild] = []
}

private struct CountingListTransformer: ValueTransformable {
    static var applyCount = 0

    typealias Object = [Int]
    typealias JSON = [String]

    func transformFromJSON(_ value: Any) -> [Int]? {
        CountingListTransformer.applyCount += 1
        guard let strings = value as? [String] else { return nil }
        return strings.compactMap { Int($0).map { $0 + 10 } }
    }

    func transformToJSON(_ value: [Int]) -> [String]? {
        value.map(String.init)
    }
}

private struct TransformerListHost: SmartCodableX {
    var scores: [Int] = []

    private enum CodingKeys: String, CodingKey {
        case scores
    }

    static func mappingForValue() -> [SmartValueTransformer]? {
        [CodingKeys.scores <--- CountingListTransformer()]
    }
}

private struct StringInputHost: SmartCodableX {
    var name: String = ""
    var mikeNo: String = "我是默认值"
}

private struct RawNestedHost: SmartCodableX {
    var count = 99
    var plainCount = 0

    private enum CodingKeys: String, CodingKey {
        case count
        case plain
    }

    init() {}
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decode(Int.self, forKey: .count)
        let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .plain)
        plainCount = try nested.decode(Int.self, forKey: .count)
    }

    func encode(to encoder: Encoder) throws {}
}

// MARK: - 回调计数 fixture

private final class MappingCountedModel: SmartCodableX {
    static var mappingCount = 0

    var level = 1

    required init() {}

    func didFinishMapping() {
        MappingCountedModel.mappingCount += 1
    }

    static func makeResolved(level: Int) -> MappingCountedModel {
        let model = MappingCountedModel()
        model.level = level
        return model
    }
}

private struct MappingCountHost: SmartCodableX {
    var child: MappingCountedModel? = MappingCountedModel()
}

private struct MappingCountArrayHost: SmartCodableX {
    var items: [MappingCountedModel] = []
}

private struct MappingTransformerHost: SmartCodableX {
    var child = MappingCountedModel()

    private enum CodingKeys: String, CodingKey {
        case child
    }

    static func mappingForValue() -> [SmartValueTransformer]? {
        [
            CodingKeys.child <--- FastTransformer<MappingCountedModel, String>(fromJSON: { value in
                guard let level = value.flatMap({ Int($0) }) else { return nil }
                return MappingCountedModel.makeResolved(level: level)
            })
        ]
    }
}

// MARK: - 审查补充 fixture

/// 第三方包装器包装 Optional 内层模型（T14）
@propertyWrapper
private struct OptionalDirectWrapper<Value: SmartDecodable & SmartEncodable>: PropertyWrapperable, Codable {
    var wrappedValue: Value?

    init(wrappedValue: Value?) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        wrappedValue = try Value(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        guard let wrappedValue else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
            return
        }
        try wrappedValue.encode(to: encoder)
    }

    static func createInstance(with value: Any) -> Self? {
        guard let value = value as? Value else { return nil }
        return Self(wrappedValue: value)
    }

    func wrappedValueDidFinishMapping() -> Self? {
        guard var value = wrappedValue else { return nil }
        value.didFinishMapping()
        return Self(wrappedValue: value)
    }
}

private struct OptionalWrapperHost: SmartCodableX {
    @OptionalDirectWrapper var payload = WrapperProbeModel()
}

/// SmartPublished 的内层模型（T26）
private struct PublishedChild: SmartCodableX {
    var level = 11
}

/// JSON 字符串数组输入宿主（T41）
private struct StringArrayInputHost: SmartCodableX {
    var models: [ArrayElementChild] = []
}

/// 继承映射用例的父类（T44）
private enum MappedBaseKeys: String, CodingKey {
    case baseValue
}

private class MappedBaseModel: SmartCodableX {
    var baseValue = 11

    required init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MappedBaseKeys.self)
        baseValue = try container.decode(Int.self, forKey: .baseValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MappedBaseKeys.self)
        try container.encode(baseValue, forKey: .baseValue)
    }

    // class func 同样满足协议的 static 要求，并允许子类按声明覆写
    class func mappingForKey() -> [SmartKeyTransformer]? {
        [MappedBaseKeys.baseValue <--- "base_value"]
    }

    class func mappingForValue() -> [SmartValueTransformer]? {
        [
            MappedBaseKeys.baseValue <--- FastTransformer<Int, String>(fromJSON: { value in
                value.flatMap(Int.init).map { $0 + 100 }
            })
        ]
    }
}

/// 继承映射用例的子类：声明自己的映射与转换器，共享同一个传入 decoder（T44）
private enum MappedDerivedKeys: String, CodingKey {
    case childValue
}

private final class MappedDerivedModel: MappedBaseModel {
    var childValue = 22

    required init() { super.init() }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: MappedDerivedKeys.self)
        childValue = try container.decode(Int.self, forKey: .childValue)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: MappedDerivedKeys.self)
        try container.encode(childValue, forKey: .childValue)
    }

    // 覆写时显式组合 super 的声明：框架不自动发现父类类型，
    // 由模型自己保证同一次子类解码中父/子映射同时生效
    override class func mappingForKey() -> [SmartKeyTransformer]? {
        (super.mappingForKey() ?? []) + [
            MappedDerivedKeys.childValue <--- "child_value"
        ]
    }

    override class func mappingForValue() -> [SmartValueTransformer]? {
        (super.mappingForValue() ?? []) + [
            MappedDerivedKeys.childValue <--- FastTransformer<Int, String>(fromJSON: { value in
                value.flatMap(Int.init).map { $0 + 200 }
            })
        ]
    }
}

/// 手写 superDecoder 用例（T45）
private struct SuperDecoderHost: SmartCodableX {
    var count = 99
    var plainCount = 0

    private enum Keys: String, CodingKey {
        case count
        case plain
    }

    init() {}
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        count = try container.decode(Int.self, forKey: .count)
        let superView = try container.superDecoder(forKey: .plain)
        let nested = try superView.container(keyedBy: Keys.self)
        plainCount = try nested.decode(Int.self, forKey: .count)
    }

    func encode(to encoder: Encoder) throws {}
}

/// 包装器回调计数模型（T46）
private final class WrapperCountedModel: SmartCodableX {
    static var mappingCount = 0

    var level = 1

    required init() {}

    func didFinishMapping() {
        WrapperCountedModel.mappingCount += 1
    }

    static func make(level: Int) -> WrapperCountedModel {
        let model = WrapperCountedModel()
        model.level = level
        return model
    }
}

private struct WrapperCountHost: SmartCodableX {
    @DirectInitWrapper var payload = WrapperCountedModel()
}

private struct WrapperTransformerHost: SmartCodableX {
    @DirectInitWrapper var payload = WrapperCountedModel()

    private enum CodingKeys: String, CodingKey {
        case payload
    }

    static func mappingForValue() -> [SmartValueTransformer]? {
        [
            CodingKeys.payload <--- FastTransformer<WrapperCountedModel, String>(fromJSON: { value in
                value.flatMap(Int.init).map(WrapperCountedModel.make)
            })
        ]
    }
}
