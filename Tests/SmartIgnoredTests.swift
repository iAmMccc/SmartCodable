import XCTest
@testable import SmartCodable

/// @SmartIgnored isEncodable 状态保持：mapping 回调重建包装器后，编码标记不能丢失
final class SmartIgnoredTests: XCTestCase {

    /// isEncodable: true 的 @SmartIgnored 属性：经过 didFinishMapping 回调后
    /// 标记依然为 true，且该属性正常参与编码输出
    func testIsEncodableSurvivesDidFinishMappingAndEncodes() throws {
        let model = try XCTUnwrap(IgnoredEncodableHost.deserialize(from: ["other": 1]))

        // mapping 回调已在内层模型上执行（证明走了 wrappedValueDidFinishMapping 重建路径）
        XCTAssertTrue(model.settings.didMappingRun)

        // 编码输出应包含被修饰属性；若重建时丢失 isEncodable，该字段会缺失。
        let encoded = try XCTUnwrap(model.toDictionary())
        let settings = try XCTUnwrap(encoded["settings"] as? [String: Any])
        XCTAssertEqual(settings["didMappingRun"] as? Bool, true)
    }

    /// isEncodable: false 的 @SmartIgnored 属性：mapping 回调后仍不参与编码
    func testNotEncodableStaysExcludedAfterMapping() throws {
        let model = try XCTUnwrap(IgnoredPlainHost.deserialize(from: ["other": 1]))

        XCTAssertTrue(model.settings.didMappingRun)
        let encoded = try XCTUnwrap(model.toDictionary())
        XCTAssertNil(encoded["settings"])
    }

    /// 直接验证 wrappedValueDidFinishMapping 重建时透传 isEncodable
    func testWrappedValueDidFinishMappingCarriesIsEncodableFlag() {
        let encodableWrapper = SmartIgnored(wrappedValue: IgnoredModel(), isEncodable: true)
        XCTAssertEqual(encodableWrapper.wrappedValueDidFinishMapping()?.isEncodable, true)

        let plainWrapper = SmartIgnored(wrappedValue: IgnoredModel(), isEncodable: false)
        XCTAssertEqual(plainWrapper.wrappedValueDidFinishMapping()?.isEncodable, false)
    }

    /// 无 parsingMark 的第三方解码路径应恢复宿主声明的完整包装器状态：
    /// 既保留 wrappedValue，也保留 isEncodable: true。
    func testWithoutParsingMarkRestoresEncodableWrapperDeclaration() throws {
        let host = try decodeWithoutParsingMark(MarklessEncodableHost.self)

        XCTAssertEqual(host.settings.level, 7)
        let encoded = try XCTUnwrap(host.toDictionary())
        let settings = try XCTUnwrap(encoded["settings"] as? [String: Any])
        XCTAssertEqual(settings["level"] as? Int, 7)
    }

    /// 同一恢复路径必须保留 isEncodable: false，不能把所有 SmartIgnored 一律设为可编码。
    func testWithoutParsingMarkKeepsNonEncodableWrapperExcluded() throws {
        let host = try decodeWithoutParsingMark(MarklessNonEncodableHost.self)

        XCTAssertEqual(host.settings.level, 7)
        let encoded = try XCTUnwrap(host.toDictionary())
        XCTAssertNil(encoded["settings"])
    }

    private func decodeWithoutParsingMark<T: SmartDecodable>(_ type: T.Type) throws -> T {
        let smartDecoder = SmartJSONDecoder()
        let impl = JSONDecoderImpl(
            userInfo: [:],
            from: .object(["settings": .object(["level": .number("999")])]),
            codingPath: [],
            options: smartDecoder.options
        )
        return try impl.unwrap(as: type)
    }
}

/// 声明 isEncodable: true 的宿主模型
private struct IgnoredEncodableHost: SmartCodableX {
    @SmartIgnored(wrappedValue: IgnoredModel(), isEncodable: true)
    var settings: IgnoredModel
}

/// 声明 isEncodable: false 的宿主模型
private struct IgnoredPlainHost: SmartCodableX {
    @SmartIgnored(wrappedValue: IgnoredModel(), isEncodable: false)
    var settings: IgnoredModel
}

/// 内层模型：记录 didFinishMapping 是否被调用
private struct IgnoredModel: SmartCodableX {
    var didMappingRun = false

    mutating func didFinishMapping() {
        didMappingRun = true
    }
}

private final class MarklessEncodableHost: SmartCodableX {
    @SmartIgnored(wrappedValue: MarklessIgnoredSettings(level: 7), isEncodable: true)
    var settings: MarklessIgnoredSettings

    required init() {}
}

private final class MarklessNonEncodableHost: SmartCodableX {
    @SmartIgnored(wrappedValue: MarklessIgnoredSettings(level: 7), isEncodable: false)
    var settings: MarklessIgnoredSettings

    required init() {}
}

private struct MarklessIgnoredSettings: SmartCodableX {
    var level: Int = 0

    init() {}

    init(level: Int) {
        self.level = level
    }
}
