import XCTest
import SmartCodable


class PerformanceTest: XCTestCase {
    var data: Data = Data()

    override func setUp() {
        super.setUp()
        data = airportsJSON(count: count)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    

//    //【1000】 0.015。 使用JSONDecoder解析遵循Codable协议的model
//    func testCodable() {
//        measure {
//            do {
//                let decoder = JSONDecoder()
//                let objects = try decoder.decode([CodableModel].self, from: data)
//                XCTAssertEqual(objects.count, count)
//            } catch {
//                XCTAssertNil(error)
//            }
//        }
//    }
//    
//    //【1000】0.026 使用SmartJSONDecoder解析遵循Codable协议的model
//    func testCleanJsonDecoder() {
//        measure {
//            do {
//                let decoder = SmartJSONDecoder()
//                let objects = try decoder.decode([CodableModel].self, from: data)
//                XCTAssertEqual(objects.count, count)
//            } catch {
//                XCTAssertNil(error)
//            }
//        }
//    }
//    
//    //【1000】 0.046 使用JSONParser解析遵循SmartCodable协议的model
//    func testSmartJsonParser() {
//        measure {
//            do {
//                let decoder = SmartJSONDecoder()
//                decoder.parserMode = .custom
//                let objects = try decoder.decode([SmartModel].self, from: data)
//                XCTAssertEqual(objects.count, count)
//            } catch {
//                XCTAssertNil(error)
//            }
//        }
//    }
//    
//    //【1000】 0.036 使用JSONSerialization解析遵循SmartCodable协议的model
//    func testSmartJSONSerialization() {
//        measure {
//            do {
//                let decoder = SmartJSONDecoder()
//                let objects = try decoder.decode([SmartModel].self, from: data)
//                XCTAssertEqual(objects.count, count)
//            } catch {
//                XCTAssertNil(error)
//            }
//        }
//    }
    // 【1000】 average: 0.040, relative standard deviation: 19.680%, values: [0.055929, 0.044426, 0.028143, 0.040032, 0.041667, 0.042019, 0.039634, 0.026208, 0.038857, 0.040737]
    func testEncodeWithJSONSerialization() throws {
        let decoder = SmartJSONDecoder()
        let objects = try decoder.decode([SmartModel].self, from: data)
        measure {
            do {
                let encoder = SmartJSONEncoder()
                let _ = try encoder.encode(objects)
            } catch {
                XCTAssertNil(error)
            }
        }
    }
    
    // 【1000】average: 0.039, relative standard deviation: 15.440%, values: [0.048204, 0.044045, 0.038840, 0.039561, 0.040793, 0.042170, 0.027042, 0.041110, 0.040413, 0.029381]
    func testEncodeWithWriter() throws {
        let decoder = SmartJSONDecoder()
        let objects = try decoder.decode([SmartModel].self, from: data)
        measure {
            do {
                let encoder = SmartJSONEncoder()
                let _ = try encoder.encode(objects)
            } catch {
                XCTAssertNil(error)
            }
        }
    }
}

// Codable & CleanJSON
struct CodableModel: Codable {
    let name: String
    let iata: String
    let icao: String
    let coordinates: [Double]
//    let runways: [Runway]

//    struct Runway: Codable {
//        enum Surface: String, Codable {
//            case rigid, flexible, gravel, sealed, unpaved, other
//        }
//        
//        let direction: String
//        let distance: Int
//        let surface: Surface
//    }
}




// SmartCodable
struct SmartModel: SmartCodable {
    
    var name: String?
    var iata: String?
    var icao: String?
    var coordinates: [Double]?
//    var runways: [Runway]?
//    
//    struct Runway: SmartCodable {
//        enum Surface: String, SmartCaseDefaultable {            
//            case rigid, flexible, gravel, sealed, unpaved, other
//        }
//        
//        var direction: String?
//        var distance: Int?
//        var surface: Surface?
//    }
}
