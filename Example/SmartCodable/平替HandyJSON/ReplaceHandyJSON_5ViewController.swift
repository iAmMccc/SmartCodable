//
//  ReplaceHandyJSON_5ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/26.
//  Copyright © 2024 CocoaPods. All rights reserved.
//


import Foundation
import UIKit
import SmartCodableKit
import HandyJSON

class ReplaceHandyJSON_5ViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict: [String: Any] = [
            "name": "Mccc",
            "age": 10
        ] as [String : Any]
        
        guard let handyModel = HandyModel.deserialize(from: dict) else { return }
        print(handyModel.name as Any)
        print(handyModel.age as Any)
        
        guard let smartModel = SmartModel.deserialize(from: dict) else { return }
        print(smartModel.name as Any)
        print(smartModel.age as Any)
    }
}
extension ReplaceHandyJSON_5ViewController {
    class HandyBaseModel: HandyJSON {
        var name: String?
        required init() { }
    }
    
    class HandyModel: HandyBaseModel {
        var age: Int?
    }
}

protocol Baseable {
    var name: String? { set get }
}

extension ReplaceHandyJSON_5ViewController {
    
    struct SmartBaseModel: SmartCodable, Baseable {
        var name: String?
    }
    
    struct SmartModel: SmartCodable, Baseable {
        var name: String?
        var age: Int?
    }
}







