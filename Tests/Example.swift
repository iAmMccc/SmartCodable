import XCTest
import SmartCodableInherit
import Foundation
@testable import SmartCodable


class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testBase() {
        let dict: [String: Any] = [
            "name": "Mccc",
            "age": 10,
            "sex": 1
        ]
        
        guard let model = Smart.deserialize(from: dict) else {
            XCTFail("反序列化失败")
            return
        }
        XCTAssertEqual(model.name, "Mccc", "Smart 的 name 应该被正确处理为字符串 'Mccc'")
        XCTAssertEqual(model.age, 10, "Smart 的 age  应该被正确处理为Int '10'")
        XCTAssertEqual(model.sex, Smart.Sex.man, "Smart 的 sex 应该被正确的处理为 Sex枚举 ‘Sex.man’")
        
        print(model)
        
    }
    
    
    func testJSONEncode() {
        var dic: [String: Any] = [
            "id": 563,
            "owner_id": 264,
            "title": "langwang004+82 ワークスペース",
            "icon": "",
            "type": 2,
            "used_seat": 1,
            "created_at": "2025-07-25T02:58:35Z",
        ]
        
        let subscription: [String: Any] = [
            "cancel_at_period_end": true,
            "current_period_end_at": "2025-07-30T03:37:03Z",
            "price_id": "personal_plan_annual_trial",
            "status": "past_due"
        ]
        dic["subscription"] = subscription as any Equatable
        
        let model = WorkspaceModel.deserialize(from: dic)
        XCTAssertNotNil(model)
        let modelDic = model?.toDictionary(useMappedKeys: true)
        XCTAssertNotNil(modelDic)
        let res = deepEqualDict(dic, modelDic!)
        XCTAssertTrue(res)
    }
}


// SmartCodable
struct Smart: SmartCodable {
    var name: String?
    var age: Int?
    var sex: Sex?
    
    enum Sex: Int, SmartCaseDefaultable {
        case man = 1
        case women = 0
    }
}


class BaseModel: SmartCodable {
    
    var name: String = ""
    

    
    required init() { }
}

@SmartSubclass
class SubModel: BaseModel {
    var age: Int = 0
    
    lazy var desc: String = {
        print("执行了")
        return "我的名字是\(self.name)"
    }()
}

// MARK: - Test JSON Encode
func deepEqual(_ lhs: Any, _ rhs: Any) -> Bool {
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

func deepEqualDict(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (key, lValue) in lhs {
        print("compare key: \(key), lValue: \(lValue)")
        guard let rValue = rhs[key] else {
            print("not found rValue for key: \(key), in rhs: \(rhs)")
            return false
        }
        if !deepEqual(lValue, rValue) {
            print("lValue: \(lValue) not equal to rValue: \(rValue)")
            return false
        }
    }
    print("key value equal in both")
    return true
}

func deepEqualArray(_ lhs: [Any], _ rhs: [Any]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (l, r) in zip(lhs, rhs) {
        if !deepEqual(l, r) {
            return false
        }
    }
    return true
}

open class SCRootModel {
    
    required public init() { }
    
    open func didFinishMapping() {
        
    }
    
    open class func mappingForKey() -> [SmartKeyTransformer]? {
        nil
    }
    
    open class func mappingForValue() -> [SmartValueTransformer]? {
        nil
    }
}


class WorkspaceModel: SCRootModel, SmartCodable {
    var id: Int = 0
    var owner_id: Int = 0
    var title: String = ""
    var icon: String = ""
    var type: Int = 0
    var used_seat: Int = 0
    var created_at: String = ""
    var subscription: WorkspaceSubscription?
}

class WorkspaceSubscription: SCRootModel, SmartCodable {
    var cancelAtPeriodEnd: Bool = false
    var currentPeriodEndAt: String = ""
    var priceid: String = ""
    var status: String = ""
    
    override class func mappingForKey() -> [SmartKeyTransformer]? {
        [
            CodingKeys.cancelAtPeriodEnd <--- "cancel_at_period_end",
            CodingKeys.currentPeriodEndAt <--- "current_period_end_at",
            CodingKeys.priceid <--- "price_id",
        ]
    }
}
