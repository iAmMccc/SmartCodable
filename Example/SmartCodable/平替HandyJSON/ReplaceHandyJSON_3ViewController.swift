//
//  ReplaceHandyJSON_3ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/26.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import SmartCodableKit
import HandyJSON

class ReplaceHandyJSON_3ViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict = [
            "nick_name": "Mccc",
            "self_age": 10
        ] as [String : Any]
        
        guard let handyModel = HandyModel.deserialize(from: dict) else { return }
        print(handyModel)
        
        guard let smartModel = SmartModel.deserialize(from: dict) else { return }
        print(smartModel)
    }
}
extension ReplaceHandyJSON_3ViewController {
    struct HandyModel: HandyJSON {
        var name: String = ""
        var age: Int?
        var ignoreKey: String = "忽略的key"
        
        mutating func mapping(mapper: HelpingMapper) {
            mapper <<<
                self.name <-- ["nick_name", "realName"]
            mapper <<<
                self.age <-- "self_age"
            mapper >>>
                self.ignoreKey
                              
        }
    }
    
    struct SmartModel: SmartCodable {
        var name: String = ""
        var age: Int?
        var ignoreKey: String = "忽略的key"
        
        enum CodingKeys: CodingKey {
            case name
            case age
//            case ignoreKey
        }

        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                CodingKeys.name <--- ["nick_name", "realName"],
                CodingKeys.age <--- "self_age"
            ]
        }
    }
}



