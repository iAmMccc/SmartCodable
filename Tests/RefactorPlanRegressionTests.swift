import Foundation
import XCTest
@testable import SmartCodable

/// Review target: fix/smartflat-snapshot-pollution @ 16f3203b4cd24fe72e3ccf49786593a92cf441fa.
///
/// 本文件是解码上下文显式绑定重构（refactor/decoder-context）的行为契约测试：
/// 前两项来自上一轮审查（R01/R02），后续补充隔离、回退、继承与 transformer 对照用例。
///
/// Run:
///   swift test --filter LatestReviewRegressionTests
final class LatestReviewRegressionTests: XCTestCase {
    /// Candidate regression: two separate model decodes within a wrapper must not reuse a
    /// mutable default object solely because scope, codingPath and model type are equal.
    func testSequentialWrappedDecodesDoNotShareMutableDefaults() throws {
        let impl = makeDecoder()
        let wrapper = try impl.unwrap(as: ReviewDecodeTwice.self)

        XCTAssertEqual(wrapper.first.box.value, 123)
        XCTAssertEqual(wrapper.wrappedValue.box.value, 10,
                       "The second decode should get a fresh default, not the first decode's mutation")
        XCTAssertFalse(wrapper.first.box === wrapper.wrappedValue.box,
                       "Independent model decodes must not unexpectedly alias a mutable default")
    }

    /// Refactor contract, not a claim that this behavior was introduced by the latest commit:
    /// a parent's already-created container should stay bound to the parent while a child is
    /// being decoded at the same JSON path. A callback exercises the retained parent container
    /// before either init(from:) has returned; this does not use a decoder after its lifetime.
    func testCapturedParentContainerKeepsItsOwnerDuringChildDecode() throws {
        let bridge = ReviewContainerBridge()
        let impl = makeDecoder(userInfo: [reviewBridgeKey: bridge])
        let parent = try impl.unwrap(as: ReviewBoundParent.self)

        XCTAssertEqual(parent.shared, 7)
        XCTAssertEqual(bridge.childDefault, 99)
        XCTAssertEqual(bridge.parentDefaultDuringChild, 7,
                       "A retained parent container must not consult the active child's defaults")
    }

    private func makeDecoder(
        userInfo: [CodingUserInfoKey: Any] = [:]
    ) -> JSONDecoderImpl {
        let decoder = SmartJSONDecoder()
        return JSONDecoderImpl(
            userInfo: userInfo,
            from: .object([:]),
            codingPath: [],
            options: decoder.options
        )
    }
}

private final class ReviewDefaultBox: Codable {
    var value = 10
}

private struct ReviewDefaultLeaf: SmartCodableX {
    var box = ReviewDefaultBox()
}

/// Deliberately decodes the same JSON value twice. Single-value decoding does not advance
/// an unkeyed-container cursor; these are two independent model initialization calls.
private struct ReviewDecodeTwice: PropertyWrapperable, Codable {
    var wrappedValue: ReviewDefaultLeaf
    var first: ReviewDefaultLeaf

    init(wrappedValue: ReviewDefaultLeaf) {
        self.wrappedValue = wrappedValue
        self.first = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        first = try container.decode(ReviewDefaultLeaf.self)
        first.box.value = 123
        wrappedValue = try container.decode(ReviewDefaultLeaf.self)
    }

    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }

    static func createInstance(with value: Any) -> Self? {
        guard let value = value as? ReviewDefaultLeaf else { return nil }
        return Self(wrappedValue: value)
    }

    func wrappedValueDidFinishMapping() -> Self? { self }
}

private var reviewBridgeKey: CodingUserInfoKey {
    CodingUserInfoKey(rawValue: "SmartCodable.LatestReview.ContainerBridge")!
}

private final class ReviewContainerBridge {
    var readParent: (() throws -> Int)?
    var childDefault: Int?
    var parentDefaultDuringChild: Int?
}

private enum ReviewSharedKeys: String, CodingKey {
    case shared
}

private struct ReviewBoundParent: SmartCodableX {
    var shared = 7

    init() {}

    init(from decoder: Decoder) throws {
        let bridge = try XCTUnwrap(decoder.userInfo[reviewBridgeKey] as? ReviewContainerBridge)
        let parentContainer = try decoder.container(keyedBy: ReviewSharedKeys.self)
        shared = try parentContainer.decode(Int.self, forKey: .shared)
        bridge.readParent = {
            try parentContainer.decode(Int.self, forKey: .shared)
        }
        defer { bridge.readParent = nil }
        let single = try decoder.singleValueContainer()
        _ = try single.decode(ReviewBoundChild.self)
    }
}

private struct ReviewBoundChild: SmartCodableX {
    var shared = 99

    init() {}

    init(from decoder: Decoder) throws {
        let bridge = try XCTUnwrap(decoder.userInfo[reviewBridgeKey] as? ReviewContainerBridge)
        let childContainer = try decoder.container(keyedBy: ReviewSharedKeys.self)
        shared = try childContainer.decode(Int.self, forKey: .shared)
        bridge.childDefault = shared
        let readParent = try XCTUnwrap(bridge.readParent)
        bridge.parentDefaultDuringChild = try readParent()
    }
}


extension LatestReviewRegressionTests {
    func testPlainCodableChildDoesNotBorrowHostDefaultTable() throws {
        let host = try XCTUnwrap(ReviewPlainHost.deserialize(from: [
            "plain": [:] as [String: Any]
        ]))
        XCTAssertEqual(host.count, 99)
        XCTAssertEqual(host.plain.count, 0)
    }

    func testWholePropertyFallbackAndInnerFieldDefaultAreDifferent() throws {
        let missing = try XCTUnwrap(
            ReviewDeclaredHost.deserialize(from: [:] as [String: Any])
        )
        let present = try XCTUnwrap(ReviewDeclaredHost.deserialize(from: [
            "child": [:] as [String: Any]
        ]))
        XCTAssertEqual(missing.child.count, 7)
        XCTAssertEqual(present.child.count, 11)
    }

    func testIndependentRootEntriesDoNotShareFreshReferenceDefaults() throws {
        let impl = makeDecoder()
        let first = try impl.unwrap(as: ReviewDefaultLeaf.self)
        first.box.value = 123
        let second = try impl.unwrap(as: ReviewDefaultLeaf.self)
        XCTAssertFalse(first.box === second.box)
        XCTAssertEqual(second.box.value, 10)
    }

    func testRepeatedLookupWithinOneModelInitKeepsDeclaredReference() throws {
        let model = try makeDecoder().unwrap(as: ReviewSameInitModel.self)
        XCTAssertTrue(model.sameDefaultReference)
        XCTAssertEqual(model.box.value, 10)
    }

    func testThrowingInnerEntryDoesNotChangeParentContainer() throws {
        let model = try makeDecoder().unwrap(as: ReviewRecoveringModel.self)
        XCTAssertEqual(model.before, 7)
        XCTAssertEqual(model.after, 7)
    }

    func testSharedDecoderInheritanceKeepsBaseAndChildDefaults() throws {
        let missing = try XCTUnwrap(
            ReviewDerivedModel.deserialize(from: [:] as [String: Any])
        )
        XCTAssertEqual(missing.baseValue, 11)
        XCTAssertEqual(missing.childValue, 22)

        let partial = try XCTUnwrap(ReviewDerivedModel.deserialize(from: [
            "baseValue": 101
        ]))
        XCTAssertEqual(partial.baseValue, 101)
        XCTAssertEqual(partial.childValue, 22)
        let encoded = try XCTUnwrap(partial.toDictionary())
        XCTAssertEqual(encoded["baseValue"] as? Int, 101)
        XCTAssertEqual(encoded["childValue"] as? Int, 22)
    }

    func testCapturedParentContainerKeepsItsTransformerDuringChildDecode() throws {
        let bridge = ReviewContainerBridge()
        let settings = SmartJSONDecoder()
        let impl = JSONDecoderImpl(
            userInfo: [reviewBridgeKey: bridge],
            from: .object(["shared": .string("5")]),
            codingPath: [],
            options: settings.options
        )
        let parent = try impl.unwrap(as: ReviewMappedParent.self)
        XCTAssertEqual(parent.shared, 15)
        XCTAssertEqual(bridge.childDefault, 105)
        XCTAssertEqual(bridge.parentDefaultDuringChild, 15)
    }
}

private struct ReviewPlain: Codable {
    var count = 0
}

private struct ReviewPlainHost: SmartCodableX {
    var count = 99
    var plain = ReviewPlain()
}

private struct ReviewDeclaredChild: SmartCodableX {
    var count = 11
    init() {}
    init(count: Int) { self.count = count }
}

private struct ReviewDeclaredHost: SmartCodableX {
    var child = ReviewDeclaredChild(count: 7)
}

private struct ReviewSameInitModel: SmartCodableX {
    var box = ReviewDefaultBox()
    var sameDefaultReference = false

    private enum CodingKeys: String, CodingKey { case box }
    init() {}
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let first = try container.decode(ReviewDefaultBox.self, forKey: .box)
        let second = try container.decode(ReviewDefaultBox.self, forKey: .box)
        sameDefaultReference = first === second
        box = second
    }
}

private enum ReviewPlanError: Error {
    case intentional
    case unexpectedlySucceeded
}

private struct ReviewThrowingModel: SmartCodableX {
    var shared = 99
    init() {}
    init(from decoder: Decoder) throws {
        throw ReviewPlanError.intentional
    }
}

private struct ReviewRecoveringModel: SmartCodableX {
    var shared = 7
    var before = 0
    var after = 0
    init() {}
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ReviewSharedKeys.self)
        before = try container.decode(Int.self, forKey: .shared)
        let single = try decoder.singleValueContainer()
        do {
            _ = try single.decode(ReviewThrowingModel.self)
            throw ReviewPlanError.unexpectedlySucceeded
        } catch ReviewPlanError.intentional {
            // Catch only the deliberate error. Any unrelated error must fail the test.
        }
        after = try container.decode(Int.self, forKey: .shared)
    }
}

private enum ReviewBaseKeys: String, CodingKey { case baseValue }
private enum ReviewDerivedKeys: String, CodingKey { case childValue }

private class ReviewBaseModel: SmartCodableX {
    var baseValue = 11
    required init() {}
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ReviewBaseKeys.self)
        baseValue = try container.decode(Int.self, forKey: .baseValue)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ReviewBaseKeys.self)
        try container.encode(baseValue, forKey: .baseValue)
    }
}

private final class ReviewDerivedModel: ReviewBaseModel {
    var childValue = 22
    required init() { super.init() }
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: ReviewDerivedKeys.self)
        childValue = try container.decode(Int.self, forKey: .childValue)
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: ReviewDerivedKeys.self)
        try container.encode(childValue, forKey: .childValue)
    }
}

private struct ReviewMappedParent: SmartCodableX {
    var shared = 7
    init() {}
    init(from decoder: Decoder) throws {
        let bridge = try XCTUnwrap(decoder.userInfo[reviewBridgeKey] as? ReviewContainerBridge)
        let parentContainer = try decoder.container(keyedBy: ReviewSharedKeys.self)
        shared = try parentContainer.decode(Int.self, forKey: .shared)
        bridge.readParent = { try parentContainer.decode(Int.self, forKey: .shared) }
        defer { bridge.readParent = nil }
        let single = try decoder.singleValueContainer()
        _ = try single.decode(ReviewMappedChild.self)
    }
    static func mappingForValue() -> [SmartValueTransformer]? {
        [ReviewSharedKeys.shared <--- FastTransformer<Int, String>(fromJSON: { value in
            value.flatMap(Int.init).map { $0 + 10 }
        })]
    }
}

private struct ReviewMappedChild: SmartCodableX {
    var shared = 99
    init() {}
    init(from decoder: Decoder) throws {
        let bridge = try XCTUnwrap(decoder.userInfo[reviewBridgeKey] as? ReviewContainerBridge)
        let container = try decoder.container(keyedBy: ReviewSharedKeys.self)
        shared = try container.decode(Int.self, forKey: .shared)
        bridge.childDefault = shared
        let readParent = try XCTUnwrap(bridge.readParent)
        bridge.parentDefaultDuringChild = try readParent()
    }
    static func mappingForValue() -> [SmartValueTransformer]? {
        [ReviewSharedKeys.shared <--- FastTransformer<Int, String>(fromJSON: { value in
            value.flatMap(Int.init).map { $0 + 100 }
        })]
    }
}
