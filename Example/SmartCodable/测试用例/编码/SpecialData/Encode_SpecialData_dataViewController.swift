//
//  Encode_SpecialData_dataViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable



class Encode_SpecialData_dataViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a": "123",
            "b": "aHR0cHM6Ly93d3cucWl4aW4uY29t"
        ]

        guard let adaptive = Model.deserialize(from: dict) else { return }
        
        smartPrint(value: adaptive)
        
        if let to = adaptive.toDictionary() {
            print(to)
        }
    }
}


extension Encode_SpecialData_dataViewController {
    struct Model: SmartCodableX {
        var a: Data?
        var b: Data?
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            return [
                CodingKeys.a <--- SmartDataTransformer()
            ]
        }
    }
}
