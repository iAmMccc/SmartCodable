//
//  Encode_SpecialData_anyViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

class Encode_SpecialData_anyViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a": "one",
            "b": [1, 2, 3, 4],
            "c": ["a": 1, "b": 2]
        ]

        guard let adaptive = Model.deserialize(from: dict) else { return }
        
        smartPrint(value: adaptive)
        
//        if let to = adaptive.toDictionary() {
//            print(to)
//        }
    }
}


extension Encode_SpecialData_anyViewController {
    struct Model: SmartCodable {
        @SmartAny
        var a: Any?
//        @SmartAny
//        var b: [Any]?
//        @SmartAny
//        var c: [String: Any]?
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            return [
                CodingKeys.a <--- OneTranformer(),
//                CodingKeys.b <--- TwoTranformer(),
//                CodingKeys.c <--- ThreeTranformer()

            ]
        }
    }
    
    struct OneTranformer: ValueTransformable {
        
        typealias Object = Any
        typealias JSON = Any
        
        func transformToJSON(_ value: Any) -> Any? {
            return value
        }
        
        func transformFromJSON(_ value: Any) -> Any? {
            return "value"
        }
    }
    
    
    struct TwoTranformer: ValueTransformable {
        
        typealias Object = [Any]
        typealias JSON = Any
        
        func transformToJSON(_ value: [Any]) -> Any? {
            return value
        }
        
        func transformFromJSON(_ value: Any) -> [Any]? {
            return ["mccc"]
        }
    }
    
    
    struct ThreeTranformer: ValueTransformable {
        
        typealias Object = [String: Any]
        typealias JSON = Any
        
        func transformToJSON(_ value: [String: Any]) -> Any? {
            return value
        }
        
        func transformFromJSON(_ value: Any) -> [String: Any]? {
            return ["key": "value"]
        }
    }
}
