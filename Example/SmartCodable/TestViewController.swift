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
            "name": "Mccc",
            "age": 32,
            "height": 182.5,
            "isMan": true
        ]

        guard let model = Model.deserialize(from: dict) else { return }
        print(model)
        
        guard let transDict = model.toDictionary() else { return }
        print(transDict)
    }
    
    
    struct Model: SmartCodable {
        var name: String = ""
        var age: Int = 0
        var height: CGFloat = 0
        var isMan: Bool = true
    }
    
    

}

