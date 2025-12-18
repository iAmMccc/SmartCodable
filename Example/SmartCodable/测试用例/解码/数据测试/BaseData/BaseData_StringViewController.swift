//
//  BaseData_StringViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/1.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

import SmartCodable

/// 兼容类String型，只兼容String类型的int值。
class BaseData_StringViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     

  
        let dict = [
            "string1": 0,
            "string2": 345.1,
            "string3": [],
            "string4": NSNull(),
            "string5": true,

        ] as [String : Any]
        
        guard let feed = CompatibleString.deserialize(from: dict) else { return }
        smartPrint(value: feed)

        /**
         string1的值为 123
         string2的值为 345.0
         string3的值为
         string4的值为 nil
         */
    }
    struct CompatibleString: SmartCodableX {
        var string1: String = ""
        var string2: String = ""
        var string3: String = ""
        var string4: String?
        var string5: String = "123"
        init() { }
    }
}





