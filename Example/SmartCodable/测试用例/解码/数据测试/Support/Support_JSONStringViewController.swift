//
//  Support_JSONStringViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/4.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable

class Support_JSONStringViewController: BaseCompatibilityViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// 浮点数的异常数据（Nan & inf）处理，不再提供demo。
        /// 底层将这两个值当成了字符串处理，遇到了就提供默认值。

        
        let dict: [String: Any] = [
            "name": "Mccc",
            "age": 10,
            "love": "{\"name\":\"sleep\"}",
            "loves": "[{\"name\":\"eat\"}]",
        ]

        
        
        if let model = JSONStringModel.deserialize(from: dict) {
            print(model)
        }
    }
    
    struct JSONStringModel: SmartCodableX {
        var name: String?
        var age: Int?
        var love: Love = Love()
        var loves: [Love] = []
    }
    
    struct Love: SmartCodableX {
        var name: String = ""
    }
}
