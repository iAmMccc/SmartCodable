//
//  ReplaceHandyJSON_4ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/26.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit

import Foundation
import UIKit
import SmartCodableKit
import HandyJSON

class ReplaceHandyJSON_4ViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict: [String: Any] = [
            "name": "Mccc",
            "dict": [
                "age": 10
            ]
        ] as [String : Any]
        
        guard let handyModel = HandyModel.deserialize(from: dict) else { return }
        print(handyModel.name ?? "")
        print(handyModel.dict)
        
        guard let smartModel = SmartModel.deserialize(from: dict) else { return }
        print(smartModel.name ?? "")
        print(smartModel.dict)
    }
}
extension ReplaceHandyJSON_4ViewController {
    struct HandyModel: HandyJSON {
        var name: Any?
        var dict: [String: Any] = [:]
    }
    
    struct SmartModel: SmartCodable {
        @SmartAny
        var name: Any?
        @SmartAny
        var dict: [String: Any] = [:]
    }
}





