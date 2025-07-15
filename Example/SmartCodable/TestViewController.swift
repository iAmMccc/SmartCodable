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
            "name": [],
            "age": 20,
            "sub": [
                "sex": NSNull(),
                "location": "Su Zhou"
            ]
        ]

        if let model = Model.deserialize(from: dict) {
            print(model)
        }
    }
    
    
    struct Model: SmartCodable {
        var name: String = ""
        @SmartAny
        var age: Any?
        @SmartAny
        var sub: SubModel?
    }
    
    
    struct SubModel: SmartCodable {
        
        enum Sex: String, SmartCaseDefaultable {
            case man
            case women
        }
        
        var sex: Sex = .man
        var location: String?
        
    }

}


extension String: SmartCodable { }

extension Int: SmartCodable { }
