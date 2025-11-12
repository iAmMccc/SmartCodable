//
//  Encode_SpecialData_modelViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit



class Encode_SpecialData_modelViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a": [
                "name": "haha"
            ]
        ]

        guard let adaptive = Model.deserialize(from: dict) else { return }
        
        smartPrint(value: adaptive)
        
        if let to = adaptive.toDictionary() {
            print(to)
        }
    }
}


extension Encode_SpecialData_modelViewController {
    struct Model: SmartCodable {
        var a: SubModel?
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.a <--- Tranformer()
            ]
        }
    }
    
    struct SubModel: SmartCodable {
        var name: String = ""
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.name <--- StringTransformer()
            ]
        }
        
    }
    
    struct StringTransformer: ValueTransformable {
        
        typealias Object = String
        typealias JSON = String
        
        func transformFromJSON(_ value: Any) -> String? {
            if let string = value as? String {
                return "my name is " + string
            }
            return nil
        }
        
        func transformToJSON(_ value: String) -> String? {
            return value
        }
    }

    
    struct Tranformer: ValueTransformable {
        
        typealias Object = SubModel
        typealias JSON = [String: Any]
        
        func transformToJSON(_ value: SubModel) -> [String: Any]? {
            return value.toDictionary()
        }
        
        func transformFromJSON(_ value: Any) -> SubModel? {
            
            if let dict = value as? [String: Any]  {
                return SubModel.deserialize(from: dict)
            }
            return nil
            
        }
    }
}
