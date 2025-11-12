//
//  ReplaceHandyJSON_2ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/26.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import SmartCodableKit
import HandyJSON

class ReplaceHandyJSON_2ViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     
        let dict = [
            "nick_name": "Mccc"
        ]
        
        guard let handyModel = HandyModel.deserialize(from: dict) else { return }
        print(handyModel)
        
        guard let smartModel = SmartModel.deserialize(from: dict) else { return }
        print(smartModel)
        
    }
}
extension ReplaceHandyJSON_2ViewController {
    struct HandyModel: HandyJSON {
        var name: String = ""
        
        mutating func didFinishMapping() {
            name = "我是\(name)"
        }
    }
    
    struct SmartModel: SmartCodable {
        var name: String = ""
        mutating func didFinishMapping() {
            name = "我是\(name)"
        }
    }
}

