//
//  KeyDecodingStrategyViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/28.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import Foundation
import SmartCodable

/** 全局的Key映射关系
 * 1. 首字母大写转小写
 * 2. 首字母小写转大写
 * 3 蛇形转驼峰命名
 * 4. 💗如有其他需求，可联系作者定制。
 */

class KeyDecodingStrategyViewController: BaseCompatibilityViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 首字母大写转小写
        let dictFirst: [String: Any] = [
            "Name": "Mccc",
            "Age": 10,
            "Sex": "男",
            "sub": [
                "Name": "小李"
            ]
        ]
        let optionFirst: SmartDecodingOption = .key(.firstLetterLower)
        if let modelFirst = ModelFirst.deserialize(from: dictFirst, options: [optionFirst]) {
            print(String(describing: modelFirst))
        } else {
            print("Failed to deserialize ModelFirst.")
        }
        
        
        
        // 首字母小写转大写
        let dictSecond: [String: Any] = [
            "name": "Mccc",
            "age": 10,
            "sex": "男",
            "sub": [
                "name": "小李"
            ]
        ]
        let optionSecond: SmartDecodingOption = .key(.firstLetterUpper)
        if let modelSecond = ModelSecond.deserialize(from: dictSecond, options: [optionSecond]) {
            print(String(describing: modelSecond))
        } else {
            print("Failed to deserialize ModelSecond.")
        }
        
        
        
        // 蛇形转驼峰命名
        let dictThird: [String: Any] = [
            "nick_name": "Mccc",
            "self_age": 10,
            "sub_info": [
                "real_name": "小李"
            ]
        ]
        let optionThird: SmartDecodingOption = .key(.fromSnakeCase)
        if let modelThird = ModelThird.deserialize(from: dictThird, options: [optionThird]) {
            print(String(describing: modelThird))
        } else {
            print("Failed to deserialize ModelThird.")
        }
    }
}


extension KeyDecodingStrategyViewController {
    struct ModelFirst: SmartCodableX {
        var name: String = ""
        var age: String = ""
        var sex: String = ""
        var sub: SubModelFirst?
    }
    
    struct SubModelFirst: SmartCodableX {
        var name: String = ""
    }
}

extension KeyDecodingStrategyViewController {
    struct ModelSecond: SmartCodableX {
        var Name: String = ""
        var Age: Int = 0
        var Sex: String = ""
        var Sub: SubModelSecond?
    }
    
    struct SubModelSecond: SmartCodableX {
        var Name: String = ""
    }
}

extension KeyDecodingStrategyViewController {
    struct ModelThird: SmartCodableX {
        var nickName: String = ""
        var selfAge: Int = 0
        var subInfo: SubModelThird?
    }
    
    struct SubModelThird: SmartCodableX {
        var realName: String = ""
    }
}

