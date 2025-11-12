//
//  Decoding_globalKeyStrategyViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit

import SmartCodableKit

class Decoding_globalKeyStrategyViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        首字母大写转小写()

        首字母小写转大写()
        
        蛇形转驼峰命名()
    }
}

extension Decoding_globalKeyStrategyViewController {
    func 首字母大写转小写() {
        let dictFirst: [String: Any] = [
            "Name": "Mccc",
            "Age": 10,
            "Sex": "男",
            "sub": [
                "Name": "小李"
            ]
        ]
        let optionFirst: SmartDecodingOption = .key(.firstLetterLower)
        if let model = ModelFirst.deserialize(from: dictFirst, options: [optionFirst]) {
            smartPrint(value: model)
        }
    }
    
    struct ModelFirst: SmartCodable {
        var name: String = ""
        var age: String = ""
        var sex: String = ""
        var sub: SubModelFirst?
    }
    
    struct SubModelFirst: SmartCodable {
        var name: String = ""
    }
}


extension Decoding_globalKeyStrategyViewController {
    func 首字母小写转大写() {
        let dictSecond: [String: Any] = [
            "name": "Mccc",
            "age": 10,
            "sex": "男",
            "sub": [
                "name": "小李"
            ]
        ]
        let optionSecond: SmartDecodingOption = .key(.firstLetterUpper)
        if let model = ModelSecond.deserialize(from: dictSecond, options: [optionSecond]) {
            smartPrint(value: model)
        }
    }
    
    struct ModelSecond: SmartCodable {
        var Name: String = ""
        var Age: Int = 0
        var Sex: String = ""
        var Sub: SubModelSecond?
    }
    
    struct SubModelSecond: SmartCodable {
        var Name: String = ""
    }
}


extension Decoding_globalKeyStrategyViewController {
    func 蛇形转驼峰命名() {
        let dictThird: [String: Any] = [
            "nick_name": "Mccc",
            "self_age": 10,
            "sub_info": [
                "real_name": "小李"
            ]
        ]
        let optionThird: SmartDecodingOption = .key(.fromSnakeCase)
        if let model = ModelThird.deserialize(from: dictThird, options: [optionThird]) {
            smartPrint(value: model)
        }
    }
    
    struct ModelThird: SmartCodable {
        var nickName: String = ""
        var selfAge: Int = 0
        var subInfo: SubModelThird?
    }
    
    struct SubModelThird: SmartCodable {
        var realName: String = ""
    }
}
