//
//  Decoding_valueMapViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/5/30.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

class Decoding_valueMapViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
      
        let dict: [String: Any] = [
            "int": 0,
            "string": "Mccc",
            "date": "2024-05-30",
            "dict": ["name": "Mccc"],
            "dict2": ["age": 10],
            "arr": [1, 2, 3],
            "subModel": [
                "name": "Mccc"
            ]
        ]
        
        if let model = Feed.deserialize(from: dict) {
            smartPrint(value: model)
        }
    }
}


extension Decoding_valueMapViewController {
    
    
    struct Feed: SmartCodable {
        var int: Int?
        var string: String?
        var date: Date?
        var subModel: SubModel?
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            
            return [
                CodingKeys.int <--- IntTranformer(),
                CodingKeys.string <--- StringTranformer(),
                CodingKeys.date <--- SmartDateTransformer(strategy: .formatted(df)),
                CodingKeys.subModel <--- SubModelTranformer()
            ]
        }
    }
    
    struct SubModel: SmartCodable {
        var name: String?
    }
    
    struct IntTranformer: ValueTransformable {
        typealias Object = Int
        typealias JSON = Int
        
        func transformFromJSON(_ value: Any) -> Int? {
            return 10
        }
        
        func transformToJSON(_ value: Int) -> Int? {
            return 10
        }
    }

    struct StringTranformer: ValueTransformable {
        typealias Object = String
        typealias JSON = String
        
        func transformFromJSON(_ value: Any) -> String? {
            return "我是Mccc"
        }
        
        func transformToJSON(_ value: String) -> String? {
            return "Mccc"
        }
    }

    struct SubModelTranformer: ValueTransformable {
        
        typealias Object = Decoding_valueMapViewController.SubModel
        typealias JSON = String
        
        func transformFromJSON(_ value: Any) -> Decoding_valueMapViewController.SubModel? {
            return Decoding_valueMapViewController.SubModel.init(name: "我是Mccc")
        }
        
        func transformToJSON(_ value: Decoding_valueMapViewController.SubModel) -> String? {
            return "Mccc"
        }
    }

}


