//
//  NonConformingFloatDecodingStrategy.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/11/30.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable


class FloatDecodingStrategyViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        let json = """
        {
          "float": "NaN"
        }
        """
        
        /**
          SmartCodable遇到 NaN的情况，会自动转换成0.0的默认值， 如果属性是可选的，将解析为nil，
         如果你对nan有特殊要求，可以实现 SmartDecodingOption 解析选项。
         */
        guard let model = FeedOne.deserialize(from: json) else {  return }
        print(model)
        // FeedOne(float: 0.0)


        
        let option: SmartDecodingOption = .float(.convertFromString(positiveInfinity: "infinity", negativeInfinity: "-infinity", nan: "NaN"))
        guard let model1 = FeedOne.deserialize(from: json, options: [option]) else {  return }
        
        print(model1)
        // FeedOne(float: nan)

        dump(model1.float) // - nan
        
    }
}



extension FloatDecodingStrategyViewController {

    struct FeedOne: SmartCodableX {
        var float: Float = 0
    }
}

