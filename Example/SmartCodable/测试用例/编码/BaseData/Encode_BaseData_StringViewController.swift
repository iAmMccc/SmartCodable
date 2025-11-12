//
//  Encode_BaseData_StringViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit



class Encode_BaseData_StringViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a": 1,
            "b": 2
        ]

        guard let adaptive = StringModel.deserialize(from: dict) else { return }
        
        smartPrint(value: adaptive)
        
        if let to = adaptive.toDictionary() {
            print(to)
        }
    }
}


extension Encode_BaseData_StringViewController {
    struct StringModel: SmartCodable {
        var a: String?
        var b: String = ""
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.a <--- StringTransformer()
            ]
        }
    }
    
    struct StringTransformer: ValueTransformable {
        
        typealias Object = String
        typealias JSON = Int
        
        func transformFromJSON(_ value: Any) -> String? {
            if let int = value as? Int {
                if int == 0 { return "0" }
                if int == 1 { return "1" }
            }
            return nil
        }
        
        func transformToJSON(_ value: String) -> Int? {
            if value == "1" {
                return 1
            } else if value == "0" {
                return 0
            }
            return nil
        }
    }
}
