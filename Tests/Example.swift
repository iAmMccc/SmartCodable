import XCTest
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
