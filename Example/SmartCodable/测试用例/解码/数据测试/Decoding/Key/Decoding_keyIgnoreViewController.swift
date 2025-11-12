//
//  Decoding_keyIgnoreViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/5/30.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

class Decoding_keyIgnoreViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        let dict1: [String: Any] = [
            "age": 10,
            "name": "Mccc",
            "location": [
                "province": "Jiang zhou",
                "city": "Su zhou",
            ]
            
        ]
        
        if let model = Model.deserialize(from: dict1) {
            smartPrint(value: model)
            print("\n")
            let dict = model.toDictionary() ?? [:]
            print(dict)
        }
    }
}




extension Decoding_keyIgnoreViewController {
    struct Model: SmartCodable {
        var name: String = ""
        var ignore: String = ""
        var age: Int = 0
        var location: Location?
        
        enum CodingKeys: CodingKey {
            case name
            // 忽略解析
//            case ignore
            case age
            case location
        }
    }
    
    struct Location: SmartCodable {
        var province: String = ""
        
        // 忽略解析
        @IgnoredKey
        var city: String = "area123"
    }
}





