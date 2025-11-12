//
//  Encode_BaseData_FloatiewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit



class Encode_BaseData_FloatiewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a": "1234",
            "b": "Mccc"
        ]

        guard let adaptive = FloatModel.deserialize(from: dict) else { return }
        
        smartPrint(value: adaptive)
        
        if let to = adaptive.toDictionary() {
            print(to)
        }
    }
}


extension Encode_BaseData_FloatiewController {
    struct FloatModel: SmartCodable {
        var a: Double?
        var b: Double = 0
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.a <--- FloatModelTransformer()
            ]
        }
    }
    
    struct FloatModelTransformer: ValueTransformable {
        
        typealias Object = Double
        typealias JSON = String
        
        
        func transformFromJSON(_ value: Any) -> Double? {
            if let temp = value as? String {
                return Double(temp)
            }
            return nil
        }
        
        func transformToJSON(_ value: Double) -> String? {
            return String(value)
        }
    }
}
