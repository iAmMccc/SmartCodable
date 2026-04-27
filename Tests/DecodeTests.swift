import XCTest
@testable import SmartCodable

/// 反序列化测试：验证从字典到模型的解码与 CodingKey 映射
final class DecodeTests: XCTestCase {
    /// 基础模型反序列化：String/Int/枚举类型正确映射
    func testDeserializeBasicModel() {
        let dict: [String: Any] = [
            "name": "Mccc",
            "age": 10,
            "sex": 1,
        ]

        let model = BasicModel.deserialize(from: dict)
        XCTAssertEqual(model?.name, "Mccc")
        XCTAssertEqual(model?.age, 10)
        XCTAssertEqual(model?.sex, .man)
    }

    /// 嵌套模型 + CodingKey 映射：snake_case 字段名自动转 camelCase
    func testWorkspaceDecodeSupportsKeyMapping() {
        let dict: [String: Any] = [
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

        let model = WorkspaceModel.deserialize(from: dict)

        XCTAssertEqual(model?.id, 563)
        XCTAssertEqual(model?.ownerId, 264)
        XCTAssertEqual(model?.title, "langwang004+82 ワークスペース")
        XCTAssertEqual(model?.usedSeat, 1)
        XCTAssertEqual(model?.createdAt, "2025-07-25T02:58:35Z")
        XCTAssertEqual(model?.subscription?.cancelAtPeriodEnd, true)
        XCTAssertEqual(model?.subscription?.currentPeriodEndAt, "2025-07-30T03:37:03Z")
        XCTAssertEqual(model?.subscription?.priceId, "personal_plan_annual_trial")
        XCTAssertEqual(model?.subscription?.status, "past_due")
    }
}
