//
//  Encode_BaseData_BoolViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable



class Encode_BaseData_BoolViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a": true,
            "b": 2
        ]

        guard let adaptive = BoolAdaptive.deserialize(from: dict) else { return }
        
        smartPrint(value: adaptive)
        
        if let to = adaptive.toDictionary() {
            print(to)
        }
    }
}


extension Encode_BaseData_BoolViewController {
    struct BoolAdaptive: SmartCodableX {
        var a: Bool?
        var b: Bool = false
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.a <--- BoolTransformer()
            ]
        }
    }
    
    struct BoolTransformer: ValueTransformable {
        
        typealias Object = Bool
        typealias JSON = Int
        
        
        func transformFromJSON(_ value: Any) -> Bool? {
            if let int = value as? Int {
                if int == 0 { return false }
                if int == 1 { return true }
            } else if let bool = value as? Bool {
                return bool
            }
            return nil
        }
        
        func transformToJSON(_ value: Bool) -> Int? {
            if value {
                return 1
            } else {
                return 0
            }
        }
    }
}




