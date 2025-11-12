//
//  Encode_BaseData_IntViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit



class Encode_BaseData_IntViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a": "123",
            "b": "Mccc"
        ]

        guard let adaptive = IntModel.deserialize(from: dict) else { return }
        
        smartPrint(value: adaptive)
        
        if let to = adaptive.toDictionary() {
            print(to)
        }
    }
}


extension Encode_BaseData_IntViewController {
    struct IntModel: SmartCodable {
        var a: Int?
        var b: Int = 0
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.b <--- BoolTransformer()
            ]
        }
    }
    
    struct BoolTransformer: ValueTransformable {
        
        typealias Object = Int
        typealias JSON = String
        
        
        func transformFromJSON(_ value: Any) -> Int? {
            if let temp = value as? String {
                return Int(temp)
            }
            return nil
        }
        
        func transformToJSON(_ value: Int) -> String? {
            return String(value)
        }
    }
}
