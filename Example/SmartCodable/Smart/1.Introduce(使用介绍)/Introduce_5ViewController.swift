//
//  Introduce_5ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/4/10.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable


/** 关于Codable中的Any
 * Any不能实现Codable，所以在使用codable的时候，一切跟Any有关的均不允许，比如[String：Any]，[Any]
 *
 * SmartCodable提供了方案
 * 方案： 使用SmartAny替代Any，如果要获取原始值，使用.peel
 
 */
class Introduce_5ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let inDict = [
            "key1": 1,
            "key2": "two",
            "key3": ["key": "one"],
            "key4": [1, 2, 3, 4]
        ] as [String : Any]
        
        let arr = [inDict]
        
        let dict = [
            "sex": true,
            "height": 184.3,
            "name": "xiao ming",
            "age": 20,
            "dict": inDict,
            "arr": arr
        ] as [String : Any]
        
        
        guard let model = AnyModel.deserialize(from: dict) else { return }
        print(model.sex ?? false)
        print(model.height ?? 0)
        print(model.name ?? "")
        print(model.age ?? 0)
        print(model.dict)
        print(model.arr)
        
        print("\n")
        print("\n")

        let encoded = model.toDictionary()
        
        let encodeDict = encoded ?? [:]
        print(encodeDict)
        print("\n")
        print("\n")

        guard let model1 = AnyModel.deserialize(from: encodeDict) else { return }
        print(model1.sex ?? false)
        print(model.height ?? 0)
        print(model1.name ?? "")
        print(model1.age ?? 0)
        print(model1.dict)
        print(model1.arr)
    }
    
   
}

extension Introduce_5ViewController {
    struct AnyModel: SmartCodableX {
        @SmartAny
        var sex: Any?
        @SmartAny
        var height: Any?
        @SmartAny
        var name: Any?
        @SmartAny
        var age: Any?
        @SmartAny
        var dict: [String: Any] = [:]
        @SmartAny
        var arr: [Any] = []
    }
}
