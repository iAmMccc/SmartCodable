//
//  FinishMappingViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/7.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable


/// 解码完成时回调
class FinishMappingViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict = [
            "name": "小花"
        ] as [String : Any]

        
        guard let model = Model.deserialize(from: dict) else { return }
        print(model)
    }
}




extension FinishMappingViewController {
    
    struct Model: SmartCodableX {
        var name: String = ""
        mutating func didFinishMapping() {
            name = "我是\(name)"
        }
    }
}





