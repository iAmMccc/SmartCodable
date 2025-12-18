//
//  CaseThreeViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/11/22.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable


class CaseThreeViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // name不会被解析
        let dict = [
            "name": "小明",
            "age": "10"
        ]
        guard let model = CaseThreeModel.deserialize(from: dict) else { return }
        print(model)


        let dict1 = [
            "nickName": "小丽",
            "age1": "20"

        ]
        guard let model1 = CaseThreeModel.deserialize(from: dict1) else { return }
        print(model1)


        let dict2 = [
            "realName": "小黄",
            "age2": "30"

        ]
        guard let model2 = CaseThreeModel.deserialize(from: dict2) else { return }
        print(model2)
    }
}

struct CaseThreeModel: SmartCodableX {
    
    var name: String = ""
    var age: String = ""
    
    static func mappingForKey() -> [SmartKeyTransformer]? {
        [
            CodingKeys.name <--- ["nickName", "realName"],
            CodingKeys.age <--- ["age", "age1", "age2"]
        ]
    }
}
