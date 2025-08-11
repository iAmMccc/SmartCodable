import XCTest
import SmartCodable
import HandyJSON


class PerformanceTest: XCTestCase {
    var data: Data = Data()
    
    var object: Any?

    override func setUp() {
        super.setUp()
        data = airportsJSON(count: count)
        
        object = data.toJSONObject()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    

    //【1000】 0.015。 使用JSONDecoder解析遵循Codable协议的model
    func testCodable() {
        measure {
            do {
                
//                let _data = jsonData(from: object)!
                
                let decoder = JSONDecoder()
                let objects = try decoder.decode([CodableModel].self, from: data)
                XCTAssertEqual(objects.count, count)
            } catch {
                XCTAssertNil(error)
            }
        }
    }
    

    //【1000】 0.036 使用JSONSerialization解析遵循SmartCodable协议的model
    func testHandyJSON() {
        measure {
            guard let objects = [HandyModel].deserialize(from: object as? [Any]) else {
                return
            }
            XCTAssertEqual(objects.count, count)
        }
    }
    // 【1000】
    func testSmart() throws {
       
        measure {
            guard let objects = [SmartModel].deserialize(from: data) else {
                return
            }
            XCTAssertEqual(objects.count, count)
        }
    }
}



struct CodableModel: Codable {
    
    var name: String?
    var iata: String?
    var icao: String?
    var coordinates: [Double]?
    var runways: [Runway]?
    
    struct Runway: Codable {
        enum Surface: String, Codable {
            case rigid, flexible, gravel, sealed, unpaved, other
        }
        
        var direction: String?
        var distance: Int?
        var surface: Surface?
    }
}

// SmartCodable
struct SmartModel: SmartCodable {
    
    var name: String?
    var iata: String?
    var icao: String?
    var coordinates: [Double]?
    var runways: [Runway]?
    
    struct Runway: SmartCodable {
        enum Surface: String, SmartCaseDefaultable {            
            case rigid, flexible, gravel, sealed, unpaved, other
        }
        
        var direction: String?
        var distance: Int?
        var surface: Surface?
    }
}

struct HandyModel: HandyJSON {
    
    var name: String?
    var iata: String?
    var icao: String?
    var coordinates: [Double]?
    var runways: [Runway]?
    
    struct Runway: HandyJSON {
        enum Surface: String, HandyJSONEnum {
            case rigid, flexible, gravel, sealed, unpaved, other
        }
        
        var direction: String?
        var distance: Int?
        var surface: Surface?
    }
}




extension Data {
    /// 尝试将 Data 解析为 JSON 对象（字典或数组）
    func toJSONObject() -> Any? {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [])
            return json
        } catch {
            print("JSON 解析失败: \(error)")
            return nil
        }
    }
}
fileprivate func jsonData(from object: Any?, prettyPrinted: Bool = false) -> Data? {
    
    guard let object = object else { return nil }
    
    guard JSONSerialization.isValidJSONObject(object) else {
        print("⚠️ 无法转成 JSON：不是合法的 JSON 对象")
        return nil
    }
    let options: JSONSerialization.WritingOptions = prettyPrinted ? .prettyPrinted : []
    return try? JSONSerialization.data(withJSONObject: object, options: options)
}
