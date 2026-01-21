//
//  DecodingLogViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2025/6/4.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable

class DecodingLogViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict: [String: Any] = [
            "type": "String",
            "sub": [:]
        ]
        
        
        let header: String = """
        url: http://www.baidu.com
        params: {
          key: value
        }
        header: {
          userId: xxxx,
          mobile: xxxx
        }
        """
        
        let footer: String = """
        时间：xxxxx
        位置：\(#file)
        其他：测试信息
        """
        
        let logContent: SmartDecodingOption = .logContext(header: header, footer: footer)
        guard let model = Model.deserialize(from: dict, options: [logContent]) else { return }
        print(model)
    }
    
    struct Model: SmartCodableX {
        var name: String = ""
        var age: Int = 0
        var sub: SubModel = SubModel()
    }
    
    struct SubModel: SmartCodableX {
        var location: String = ""
        var hobby: String = ""
    }
}
