//
//  TestViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/1.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import SmartCodable
import HandyJSON
import CleanJSON
import BTPrint


class TestViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        let dict: [String: Any] = [
            "age": 5,
            "name": "Mccc",
            "loves":["ball"],
        ]

        guard let model = Model.deserialize(from: dict) else { return }
        print(model)
    }
    
    
    struct Model: SmartCodable {
        @SmartFlat
        var son: Son?
    }
    
    struct Son: SmartCodable {
        var name: String = ""
        var age: Int = 0
        var loves: [String]?
    }
}

