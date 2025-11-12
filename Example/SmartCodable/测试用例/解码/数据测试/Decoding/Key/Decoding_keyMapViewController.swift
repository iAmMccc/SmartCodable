//
//  Decoding_keyMapViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/5/30.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

class Decoding_keyMapViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let dict1: [String: Any] = [
            "age": 10,
            "nickName": "Mccc",
            "area": [
                "province": "Jiang zhou",
                "cityName": "Su zhou",
            ],
            "son": "{\"hobbyName\":\"sleep\"}"
        ]
        
        if let model = Model.deserialize(from: dict1) {
            smartPrint(value: model)
        }
    }
}




extension Decoding_keyMapViewController {
    struct Model: SmartCodable {
        var name: String = ""
        var age: Int = 0
        var location: Location?
        var son: Son?
        
        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                CodingKeys.name <--- "nickName",
                CodingKeys.location <--- "area"
            ]
        }
    }
    
    struct Location: SmartCodable {
        var province: String = ""
        var city: String = ""
        
        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                CodingKeys.city <--- "cityName"
            ]
        }
    }
    
    struct Son: SmartCodable {
        var hobby: String = ""
        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                CodingKeys.hobby <--- "hobbyName"
            ]
        }
    }
}





