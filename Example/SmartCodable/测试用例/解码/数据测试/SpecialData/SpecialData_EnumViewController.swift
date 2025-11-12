//
//  SpecialData_EnumViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

// todo enum
import SmartCodableKit

class SpecialData_EnumViewController: BaseCompatibilityViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// 浮点数的异常数据（Nan & inf）处理，不再提供demo。
        /// 底层将这两个值当成了字符串处理，遇到了就提供默认值。

        
        let dict: [String: Any] = [
            "a": NSNull(),
            "b": "123",
            "c": [],
            "d": "one",
            "e": "two"
        ]

        if let model = EnumModel.deserialize(from: dict) {
            print(model)
        
        }
        
    }
    
    struct EnumModel: SmartCodable {
        var a: NunmberEnum?
        var b: NunmberEnum?
        var c: NunmberEnum?
        var d: NunmberEnum?
        var e: NunmberEnum = .one
    }
    
    
    enum NunmberEnum: String, SmartCaseDefaultable {                
        case one
        case two
        case three
    }
}
