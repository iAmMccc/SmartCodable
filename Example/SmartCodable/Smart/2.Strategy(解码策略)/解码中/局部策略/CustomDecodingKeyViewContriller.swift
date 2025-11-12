//
//  CustomDecodingPathViewContriller.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/4/10.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit
/** Key的映射关系
 * 1. 字段的重命名
 * 2. 支持多个字段重命名到一个属性上
 * 3. 支持自定义解析路径
 */
class CustomDecodingKeyViewContriller: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let dict = [
            "nickName": "小花",
            "person_age": 10,
            "sexDict": [
                "sex": "男"
            ]
        ] as [String : Any]


        guard let model = Model.deserialize(from: dict) else { return }
        print(model)

        
        
        let dict1 = [
            "nickName": NSNull(),
            "realName": "小花",
            "age": 10,
            "person_age": 20,
            "sex": "女"
        ] as [String : Any]

        
        guard let model = Model.deserialize(from: dict1) else { return }
        print(model)
    }
}



extension CustomDecodingKeyViewContriller {
    
    struct Model: SmartCodable {
        var name: String = ""
        var age: Int?
        var sex: String?
        
        
        /// ⚠️： 你也可以通过重写CodingKeys实现key的重命名
        enum CodingKeys: String, CodingKey {
            case name
            case age = "person_age"
            case sex
        }
        
        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                CodingKeys.name <--- ["nickName", "realName"],
//                CodingKeys.age <--- "person_age",
                // 如果当前数据结构中有 sex，就不做映射。
                CodingKeys.sex <--- "sexDict.sex"
            ]
        }
    }
}


