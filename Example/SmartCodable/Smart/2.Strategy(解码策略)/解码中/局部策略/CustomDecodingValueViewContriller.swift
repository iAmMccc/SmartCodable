//
//  CustomDecodingValueViewContriller.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/4/10.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit


/// 自定义Value的解析策略
class CustomDecodingValueViewContriller: BaseViewController {

    var model: SmartModel?
    override func viewDidLoad() {
        super.viewDidLoad()

        let dict1: [String: Any] = [
            "string": "Mccc",
            "int": 10,
            "double": 10.0,
            "bool": "Mccc",
            "cgFloat": 20.0,
            
            "date": "2024-04-07",
            "date2": 1712491290,
            
            "url": "www.baidu.com",
            
            "color": "7DA5E3",
            
            "sub": [
                "subDate": 1712491290,
                "subColor": "7DA5E3",
                "subData": "aHR0cHM6Ly93d3cucWl4aW4uY29t"
            ]
        ]
        guard let model1 = SmartModel.deserialize(from: dict1) else { return }
        model = model1
        print(model1)
        
        print("\n")
        
        if let data = model?.sub?.subData, let url = String(data: data, encoding: .utf8) {
            print(url)
            // https://www.qixin.com
        }
        
        guard let dataValue = model1.toDictionary() else { return }
        print(dataValue)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.backgroundColor = model?.color
//        if let url = model?.url {
//            UIApplication.shared.open(url)
//        }
    }
}


extension CustomDecodingValueViewContriller {
    
    struct SmartModel: SmartCodable {
        
        var string: String = ""
        var int: Int = 0
        var bool: Bool = false
        var cgFloat: CGFloat = 0.0
        var double: Double = 0.0

        var date1: Date?
        var date2: Date?
        
        var url: URL?
        
        var ignoreKey: String?
        @SmartHexColor
        var color: UIColor?
        
        var sub: SmartSubModel?
        

        // value的解析策略
        static func mappingForValue() -> [SmartValueTransformer]? {
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd"
            return [
                CodingKeys.string <--- StringTransformer(),
                CodingKeys.int <--- IntTransformer(),
                CodingKeys.double <--- DoubleTransformer(),
                CodingKeys.bool <--- BoolTransformer(),
                CodingKeys.cgFloat <--- CGFloatTransformer(),
                
                CodingKeys.url <--- SmartURLTransformer(prefix: "https://"),
                CodingKeys.date2 <--- SmartDateTransformer(strategy: .timestamp),
                CodingKeys.date1 <--- SmartDateTransformer(strategy: .formatted(format))
            ]
        }
    }
    
    struct SmartSubModel: SmartCodable {

        var subDate: Date?
        @SmartHexColor
        var subColor: UIColor?
        var subData: Data?

        
        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                CodingKeys.subDate <--- "date2",
            ]
        }
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.subData <--- SmartDataTransformer(),

                CodingKeys.subDate <--- SmartDateTransformer(strategy: .timestamp),
            ]
        }
    }
}


extension CustomDecodingValueViewContriller {
    struct StringTransformer: ValueTransformable {
        func transformToJSON(_ value: String) -> String? {
            return value
        }
        
        func transformFromJSON(_ value: Any) -> String? {
            if let temp = value as? String {
                return "前缀" + temp
            }
            return nil
        }
        
        typealias Object = String
        typealias JSON = String
    }
    
    struct IntTransformer: ValueTransformable {
        func transformToJSON(_ value: Int) -> Int? {
            return value
        }
        
        func transformFromJSON(_ value: Any) -> Int? {
            if let temp = value as? Int {
                return 100 + temp
            }
            return nil
        }
        
        typealias Object = Int
        typealias JSON = Int
    }
    
    struct DoubleTransformer: ValueTransformable {
        func transformToJSON(_ value: Double) -> Double? {
            return value
        }
        
        func transformFromJSON(_ value: Any) -> Double? {
            if let temp = value as? Double {
                return 100 + temp
            }
            return nil
        }
        
        typealias Object = Double
        typealias JSON = Double
    }
    
    struct CGFloatTransformer: ValueTransformable {
        func transformToJSON(_ value: CGFloat) -> CGFloat? {
            return value
        }
        
        func transformFromJSON(_ value: Any) -> CGFloat? {
            if let temp = value as? CGFloat {
                return 100 + temp
            }
            return nil
        }
        
        typealias Object = CGFloat
        typealias JSON = CGFloat
    }

    
    struct BoolTransformer: ValueTransformable {
        func transformToJSON(_ value: Bool) -> String? {
            if value {
                return "Mccc"
            } else {
                return nil
            }
        }
        
        func transformFromJSON(_ value: Any) -> Bool? {
            if let temp = value as? String {
                if temp == "Mccc" {
                    return true
                }
            }
            return nil
        }
        
        typealias Object = Bool
        typealias JSON = String
    }

}
