//
//  Introduce_11ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/11.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable


class Introduce_11ViewController: BaseCompatibilityViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dic1: [String : Any] = [
            "name": "mccc",
            "age": 10
        ]
        let dic2: [String : Any] = [
            "age": 200
        ]
        
        guard var model = Model.deserialize(from: dic1) else { return }
//        SmartUpdater.update(&model, from: dic2)
        smartPrint(value: model)
    }
    struct Model: SmartCodableX {
        var name: String = ""
        var age: Int = 0
    }
}



