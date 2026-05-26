import XCTest
@testable import SmartCodable

/// 序列化测试：验证模型编码时 CodingKey 映射的还原行为
final class EncodeTests: XCTestCase {
    /// toDictionary(useMappedKeys:)：编码时使用 CodingKey 映射还原原始字段名
    func testToDictionaryUseMappedKeysProducesOriginalPayloadShape() {
        let original: [String: Any] = [
            "id": 563,
            "owner_id": 264,
            "title": "langwang004+82 ワークスペース",
            "icon": "",
            "type": 2,
            "used_seat": 1,
            "created_at": "2025-07-25T02:58:35Z",
            "subscription": [
                "cancel_at_period_end": true,
                "current_period_end_at": "2025-07-30T03:37:03Z",
                "price_id": "personal_plan_annual_trial",
                "status": "past_due",
            ],
        ]

        let model = WorkspaceModel.deserialize(from: original)
        let encoded = model?.toDictionary(useMappedKeys: true)

        XCTAssertNotNil(encoded)
        XCTAssertEqual(encoded?["id"] as? Int, 563)
        XCTAssertEqual(encoded?["owner_id"] as? Int, 264)
        XCTAssertEqual(encoded?["title"] as? String, "langwang004+82 ワークスペース")
        XCTAssertEqual(encoded?["icon"] as? String, "")
        XCTAssertEqual(encoded?["type"] as? Int, 2)
        XCTAssertEqual(encoded?["used_seat"] as? Int, 1)
        XCTAssertEqual(encoded?["created_at"] as? String, "2025-07-25T02:58:35Z")

        let subscription = encoded?["subscription"] as? [String: Any]
        XCTAssertEqual(subscription?["cancel_at_period_end"] as? Bool, true)
        XCTAssertEqual(subscription?["current_period_end_at"] as? String, "2025-07-30T03:37:03Z")
        XCTAssertEqual(subscription?["price_id"] as? String, "personal_plan_annual_trial")
        XCTAssertEqual(subscription?["status"] as? String, "past_due")
    }

    /// toJSONString(useMappedKeys:)：JSON字符串输出中包含映射后的原始字段名
    func testToJSONStringIncludesMappedKeysWhenRequested() {
        var model = WorkspaceSubscription()
        model.cancelAtPeriodEnd = true
        model.currentPeriodEndAt = "2025-07-30T03:37:03Z"
        model.priceId = "personal_plan_annual_trial"
        model.status = "past_due"

        let json = model.toJSONString(useMappedKeys: true)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"cancel_at_period_end\":true") == true)
        XCTAssertTrue(json?.contains("\"current_period_end_at\":\"2025-07-30T03:37:03Z\"") == true)
        XCTAssertTrue(json?.contains("\"price_id\":\"personal_plan_annual_trial\"") == true)
    }
}
