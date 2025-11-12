//
//  Introduce_4ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/8.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable


/// 属性对象参与解析
class Introduce_4ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict = [
            "subModel1": [
                "name": 123
            ],
            "subModel2": [
                "name": "小花"
            ],
            "subList1": [
                [
                    "name": "小黄"
                ]
            ],
            "subList2": [
                [
                    "name": "小华"
                ]
            ]
            
        ] as [String : Any]

        
        guard let model = BigModel.deserialize(from: dict) else { return }
        print(model)
        
    }
}


extension Introduce_4ViewController {
    
    struct BigModel: SmartCodableX {
        var subModel1: SubModel?
        var subModel2: SubModel = SubModel()
        var subList1: [SubModel]?
        var subList2: [SubModel] = []
    }
    
    struct SubModel: SmartCodableX {
        var name: String = ""
    }
}



