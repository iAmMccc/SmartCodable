//
//  Container_DictNestArrayViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import SmartCodable

class Container_DictNestArrayViewController: BaseCompatibilityViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        

        let dict: [String: Any] = [
            "name": "Mccc",
            "age": 30,
            "loves": [
                [
                    "name": "basketball",
                    "time": 10
                ],
                [
                    "name": "football",
                    "time": 10
                ]
            ],
            "sons": [
                [
                    "name": "son1",
                    "age": 4,
                    "love": [
                        "name": "sleep",
                        "time": 4
                    ],
                ],
                [
                    "name": "son2",
                    "age": 4,
                    "love": [
                        "name": "look Books",
                        "time": 2
                    ],
                ]
            ]
        ]
        


       
        if let model = FatherModel.deserialize(from: dict) {
            smartPrint(value: model)
        }
    }

}
extension Container_DictNestArrayViewController {
    struct FatherModel: SmartCodableX {
        
        var name: String = ""
        var age: Int = 0
        var loves: [Love] = []
        var sons: [SonModel] = []
    }

    struct SonModel: SmartCodableX {
        var name: String?
        var age: Int?
        var love: Love?
    }

    struct Love: SmartCodableX {
        var name: String = ""
        var time: CGFloat = 0.0
    }
}
