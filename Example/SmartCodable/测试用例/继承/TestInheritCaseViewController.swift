//
//  TestInheritCaseViewController.swift
//  SmartCodable_Example
//
//  Created by qixin on 2025/5/6.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation

import UIKit
import SmartCodable





class TestInheritCaseViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        let dict: [String: Any] = [
            "superName": "Mccc",
            "age": "18",
            "desc": "good boy",
            "sub_location": "su zhou",
            "sex": 1,
            "birthDate": "2000-01-01",
            "date": "2025-05-06",
            "hobbys": ["ball", "TV"]
        ]
 
        guard let model = SubModel.deserialize(from: dict) else { return }
        
        smartPrint(value: model)
        
        let encodeDict = model.toJSONString(prettyPrint: true) ?? ""
        print(encodeDict)
    }


    class BaseModel: SmartCodableX {
        var name: String = ""
        var age: Int?
        var date: Date?
        @SmartAny var desc: Any?
        
        
        class func mappingForKey() -> [SmartKeyTransformer]? {
            return [ CodingKeys.name <--- "superName" ]
        }
        
        class func mappingForValue() -> [SmartValueTransformer]? {
            let tf = DateFormatter()
            tf.dateFormat = "yyyy-MM-dd"
            return [ CodingKeys.date <--- SmartDateTransformer(strategy: .formatted(tf)) ]
        }
        
        func didFinishMapping() {
            print("父类完成了解析")
        }
        required init() { }
    }
    
    
    @SmartSubclass
    class SubModel: BaseModel {
        var location: String = ""
        var sex: Sex = .man
        var birthDate: Date?
        
        @SmartAny var hobbys:[Any] = []
        
        override static func mappingForKey() -> [SmartKeyTransformer]? {
            let trans = [ CodingKeys.location <--- "sub_location" ]
            if let superTrans = super.mappingForKey() {
                return superTrans + trans
            } else {
                return trans
            }
        }
        
        override static func mappingForValue() -> [SmartValueTransformer]? {
            let tf = DateFormatter()
            tf.dateFormat = "yyyy-MM-dd"
            let trans = [ CodingKeys.birthDate <--- SmartDateTransformer(strategy: .formatted(tf)) ]

            if let superTrans = super.mappingForValue() {
                return superTrans + trans
            } else {
                return trans
            }
        }
        
        override func didFinishMapping() {
            super.didFinishMapping()
            print("子类完成了解析")
        }
    }
    
    enum Sex: Int, SmartCaseDefaultable {
        case man = 1
        case women = 0
    }
}


