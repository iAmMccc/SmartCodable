//
//  Container_DictNestDictViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import SmartCodable

class Container_DictNestDictViewController: BaseCompatibilityViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
       
        let dict: [String: Any] = [
            "name": "father",
            "age": 30,
            "love": [
                "name": "basketball",
                "time": 10
            ],
            "son": [
                "name": "son",
                "age": 4,
                "love": [
                    "name": "sleep",
                    "time": 4
                ],
            ]
        ]

       
        if let model = FatherModel.deserialize(from: dict) {
            smartPrint(value: model)
        }
    }

}


extension Container_DictNestDictViewController {
    struct FatherModel: SmartCodableX {
        var name: String = "father"
        var age: Int = 100
        var love: Love = Love()
        var son: SonModel = SonModel()
    }
    
    struct SonModel: SmartCodableX {
        var name: String?
        var age: Int?
        var love: Love?
    }
    
    struct Love: SmartCodableX {
        var name: String = "足球"
        var time: CGFloat = 5.5
    }
}
