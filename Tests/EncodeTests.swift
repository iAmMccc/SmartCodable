import XCTest
@testable import SmartCodable

/// Serialization tests for restoring CodingKey mappings while encoding models.
final class EncodeTests: XCTestCase {
    /// Regression test model for encode-only conformance with no custom mapping hooks.
    struct EncodableOnlyModel: SmartEncodable {
        var name: String = "linus"
        var age: Int = 42
    }

    func testSmartEncodableProvidesMappingDefaults() {
        XCTAssertNil(EncodableOnlyModel.mappingForKey())
        XCTAssertNil(EncodableOnlyModel.mappingForValue())

        var model = EncodableOnlyModel()
        model.didFinishMapping()

        let encoded = model.toDictionary()
        XCTAssertEqual(encoded?["name"] as? String, "linus")
        XCTAssertEqual(encoded?["age"] as? Int, 42)
    }

    /// toDictionary(useMappedKeys:) restores original field names from CodingKey mappings.
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

    /// toJSONString(useMappedKeys:) includes mapped original field names in JSON output.
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
