//
//  AreaTest.swift
//  SmartCodable_Tests
//
//  Created by Mccc on 2024/1/12.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import XCTest
import SmartCodableKit
import HandyJSON
import HandyJSON
import CleanJSON


let areaCount = 31


class AreaTest: XCTestCase {
    
    var areaData: Data = Data()
    override func setUp() {
        super.setUp()
        areaData = areaJSON()

    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // 0.048
    func testAreaHandyJSON() {
        measure {
            let json = String(data: areaData, encoding: .utf8)
            let objects = JSONDeserializer<AreaHandy>.deserializeModelArrayFrom(json: json)
            XCTAssertEqual(objects?.count, areaCount)
        }
    }
    
    // 0.013
    func testAreaCodable() {
        measure {
            do {
                let decoder = JSONDecoder()
                let objects = try decoder.decode([AreaCodable].self, from: areaData)
                XCTAssertEqual(objects.count, areaCount)
            } catch {
                XCTAssertNil(error)
            }
        }
    }
    
    // 0.021
    func testCleanCodable() {
        measure {
            do {
                let decoder = CleanJSONDecoder()
                let objects = try decoder.decode([AreaCodable].self, from: areaData)
                XCTAssertEqual(objects.count, areaCount)
            } catch {
                XCTAssertNil(error)
            }
        }
    }

    // 0.024
    func testAreaSmartJSONDecoder() {
        measure {
            do {
                let decoder = SmartJSONDecoder()
                let objects = try decoder.decode([AreaCodable].self, from: areaData)
                XCTAssertEqual(objects.count, areaCount)
            } catch {
                XCTAssertNil(error)
            }
        }
    }

    // 0.035
    func testAreaSmart() {
        measure {
            guard let objects = [AreaSmart].deserialize(from: areaData) else {
                return
            }
            
            XCTAssertEqual(objects.count, areaCount)
        }
    }
}


func areaJSON() -> Data {
    let resource = "area"
    let url = Bundle.main.url(forResource: resource, withExtension: "json")
    guard let url = url,
        let data = try? Data(contentsOf: url) else {
            fatalError()
    }
    return data
}


// HandyJSON
struct AreaHandy: HandyJSON {
    
    var areaCode: String = ""
    var name: String = ""
    var city: [City] = []
    
    struct City: HandyJSON {
        var name: String = ""
        var areaCode: String = ""
        var district: [District] = []
        
        struct District: HandyJSON {
            var name: String = ""
            var areaCode: String = ""
        }
    }
}




// Codable & CleanJSON
struct AreaCodable: Codable {
    
    var areaCode: String = ""
    var name: String = ""
    var city: [City] = []
    
    struct City: Codable {
        var name: String = ""
        var areaCode: String = ""
        var district: [District] = []
        
        struct District: Codable {
            var name: String = ""
            var areaCode: String = ""
        }
    }
}




// SmartCodable
struct AreaSmart: SmartCodable {
    
    
    var areaCode: String = ""
    var name: String = ""
    var city: [City] = []
    
    struct City: SmartCodable {
        var name: String = ""
        var areaCode: String = ""
        var district: [District] = []
        
        struct District: SmartCodable {
            var name: String = ""
            var areaCode: String = ""
        }
    }
}



