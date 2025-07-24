//
//  Test2ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/4/10.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SmartCodable




class Test2ViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict: [String: Any] = [


            "name": "Mccc",
            
            "height": 188.5,
            
            "sex": true,
            
            "dict": ["abc": "Test"],
            
            "arr": [
                "1", "2", "3"
            ]

        ]

        guard let model = Model.deserialize(from: dict) else { return }
        smartPrint(value: model)
        
//        guard let transDict = model.toJSONString(prettyPrint: true) else { return }
//        print(transDict)
    }
}


extension Test2ViewController {
    struct Model: SmartCodable {
        
        var age: CGFloat = 72.0/278.0
        
//        @SmartAny
//        var name: Any?
//        
//        @SmartAny
//        var sex: Any?
//        
//        @SmartAny
//        var height: Any?
//        
//        @SmartAny
//        var dict: [String: Any]?
//        
//        @SmartAny
//        var arr: [Any]?
    }
}
