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
            "int": 1,
            "bool": true,
            "string": "mccc",
            "double": 200.0,
            "cgFloat": 200.0,
            "float": 200.0,
            "subModel": [
                "name": "Sub Mccc"
            ]
        ]
        
        guard let model = Model.deserialize(from: dict) else { return }
        print(model)
        
        guard let transDict = model.toJSONString(prettyPrint: true) else { return }
        print(transDict)
    }
    
    struct Model: SmartCodable {

//        var int: Int = 100
//        var bool: Bool = true
//        var string: String = "Mccc"
//        var double: Double = 100.0
//        var cgFloat: CGFloat = 100.0
//        var float: Float = 100.0
        var subModel: SubModel = SubModel()
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
//                CodingKeys.int <--- IntTranformer(),
//                CodingKeys.bool <--- BoolTranformer(),
//                CodingKeys.string <--- Tranformer(),
//                CodingKeys.double <--- Tranformer(),
//                CodingKeys.cgFloat <--- Tranformer(),
//                CodingKeys.float <--- Tranformer(),
//                CodingKeys.date <--- SmartDateTransformer(strategy: .timestamp)
//                CodingKeys.color <--- SmartHexColorTransformer(colorFormat: .rrggbb(.none))
//                CodingKeys.name <--- Tranformer()
                CodingKeys.subModel <--- SubTranformer()
            ]
        }
    }
    
    struct SubModel: SmartCodable {
        var name: String = "Mccc"
    }
    
    struct IntTranformer: ValueTransformable {
        func transformFromJSON(_ value: Any) -> Object? {
            return 300
        }
        
        func transformToJSON(_ value: Object) -> JSON? {
            return "300"
        }
        
        typealias Object = Int
        
        typealias JSON = String
    }
    
    
    struct SubTranformer: ValueTransformable {
        func transformFromJSON(_ value: Any) -> Object? {
            return SubModel(name: "subsubsub")
        }
        
        func transformToJSON(_ value: Object) -> JSON? {
            return ["name": "subsubsub"]
        }
        
        typealias Object = SubModel
        
        typealias JSON = [String: Any]
    }

    
}


struct BoolTranformer: ValueTransformable {
    func transformFromJSON(_ value: Any) -> Object? {
        return true
    }
    
    func transformToJSON(_ value: Object) -> JSON? {
        return nil
    }
    
    typealias Object = Bool
    
    typealias JSON = String
}


