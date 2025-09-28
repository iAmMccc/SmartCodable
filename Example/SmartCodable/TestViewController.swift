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



/** 5.1.0更新日志
 1. 重构数据转换方式，抛弃`JSONParser`，使用官方的`JSONSerialization`。让解析更安全。
 2. 明确 `DecodingCache` 和 `EncodingCache` 的路径是当前 `Container` 的 `codingPath`，通过key在其中寻找对应的初始化值或值解析器。
 3. 梳理并优化值解析器逻辑。
 4. `@IgnoredKey` 更名为 `@SmartIgnored`.
 5. 优化 `CGFloat` 解析逻辑，`CGFloat` 在解析中是一个复合容器，可以划归跟`URL`、`Date`同样的处理方式。
 */


class TestViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        

        
        let dict: [String: Any] = [
            "age": 0,
            "name": "操作成功",

        ]
        
        guard let model = SubModel.deserialize(from: dict) else { return }
        print(model)
    }

    class Model: SmartCodable {
        var name: String = ""
        
        required init() { }
    }
    
    @SmartSubclass
    class SubModel: Model {
        @objc var age: String = ""
        
        @SmartAny
        var location: String = ""
        
    }
}

