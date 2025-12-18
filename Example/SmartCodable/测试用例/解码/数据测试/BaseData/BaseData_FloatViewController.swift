//
//  BaseData_FloatViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/1.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

import SmartCodable

// 使用属性包装器，提供一个默认配置？？ 看看是否可以实现， 提供NaN， nan

/// 针对浮点数进行nan兼容，只支持“nan”判断。 如果返回"NaN"等，会解析失败。
class BaseData_FloatViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let json = """
        {
          "floatValue": "NaN",
          "floatValue1": "123",
          "floatValue2": "abc",

          "cgfloatValue": "nan",
          "doubleValue": "nan",
        }
        """
        guard let model = CompatibleFloat.deserialize(from: json) else { return }
        smartPrint(value: model)
        
        /**
         0.0
         123.0
         0.0
         nil
         0.0
         0.0
         */
    }
    
    struct CompatibleFloat: SmartCodableX {
        var floatValue: Float = 0
        var floatValue1: Float = 0
        var floatValue2: Float = 0
        var floatValue3: Float = 0
        var floatValue4: Float?


        var cgfloatValue: CGFloat = 0
        var doubleValue: Double = 0
        init() { }
    }
}






