//
//  Container_keyedViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/7/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

/// 兼容Int类型，只兼容String类型的int值。
class Container_keyedViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     
        
//        let dict1 = getDict1()
//        guard let feed = Model1.deserialize(from: dict1) else { return }
//        smartPrint(value: feed)
        
        
//        let dict2 = getDict2()
//        guard let feed2 = Model2.deserialize(from: dict2) else { return }
//        smartPrint(value: feed2)

        
//        let dict3 = getDict3()
//        guard let feed3 = Model3.deserialize(from: dict3) else { return }
//        smartPrint(value: feed3)

        
        let dict4 = getDict4()
        guard let feed4 = Model4.deserialize(from: dict4) else { return }
        smartPrint(value: feed4)
    }

}




/// 验证是keyedcontainer容器是字典的情况
extension Container_keyedViewController {
    
    func getDict1() -> [String: Any] {
        return [
            "dict2": NSNull(),
            "dict3": 123,
            "dict4": ["a": 1, "b": "2", "c": "3"],
            
            "dict6": NSNull(),
            "dict7": 123,
            "dict8": ["a": 1, "b": "2", "c": "3"]
        ]
    }
    
    
    struct Model1: SmartCodable {
        
        // 无key
        var dict1: [String: String] = [:]
        // 值为null
        var dict2: [String: String] = [:]
        // 值类型错误
        var dict3: [String: String] = [:]
        // 元素类型支持类型转换，如果转换失败，则返回初始化值
        var dict4: [String: String] = [:]

        
        var dict5: [String: String]?
        var dict6: [String: String]?
        var dict7: [String: String]?
        var dict8: [String: String]?
    }
}


/// 验证是keyedcontainer容器是Model的情况
extension Container_keyedViewController {
    
    func getDict2() -> [String: Any] {
        return [
            "model2": NSNull(),
            "model3": 123,
            "model4": ["name": "mccc", "age": "20"],
            
            "model6": NSNull(),
            "model7": 123,
            "model8": ["name": "mccc", "age": "20"],
        ]
    }
    
    
    struct Model2: SmartCodable {
        
        // 无key
        var model1 = SubModel()
        // 值为null
        var model2 = SubModel()
        // 值类型错误
        var model3 = SubModel()
        // 元素类型支持类型转换，如果转换失败，则返回初始化值
        var model4 = SubModel()

        
        var model5: SubModel?
        var model6: SubModel?
        var model7: SubModel?
        var model8: SubModel?
    }
    
    struct SubModel: SmartCodable {
        var name: String = ""
        var age: Int?
    }
}

/// 验证是keyedcontainer容器下，使用SmartAny
extension Container_keyedViewController {
    
    func getDict3() -> [String: Any] {
        return [
            "dict2": NSNull(),
            "dict3": 123,
            "dict4": ["name": "mccc", "age": "20"],
            
            "dict6": NSNull(),
            "dict7": 123,
            "dict8": ["name": "mccc", "age": "20"],
        ]
    }
    
    
    struct Model3: SmartCodable {
        
        // 无key
        @SmartAny
        var dict1: [String: Any] = [:]
        // 值为null
        @SmartAny
        var dict2: [String: Any] = [:]
        // 值类型错误
        @SmartAny
        var dict3: [String: Any] = [:]
        // 元素类型支持类型转换，如果转换失败，则返回初始化值
        @SmartAny
        var dict4: [String: Any] = [:]

        @SmartAny
        var dict5: [String: Any]?
        @SmartAny
        var dict6: [String: Any]?
        @SmartAny
        var dict7: [String: Any]?
        @SmartAny
        var dict8: [String: Any]?
    }
}

/// 验证是keyedcontainer容器下，使用SmartAny
extension Container_keyedViewController {
    
    func getDict4() -> [String: Any] {
        return [
            "name": "Mccc",
            "age": 18,
            "model": [
                "name": "Mccc1",
                "age": 188,
            ]
        ]
    }
    
    
    struct Model4: SmartCodable {
      
        var name: String = ""
        var age: Int = 0
      
        @SmartFlat
        var model: FlatModel?
       
    }
    
    struct FlatModel: SmartCodable {
        var name: String = ""
        var age: Int = 0
        
        func didFinishMapping() {
            print("执行了didFinishMapping")
        }
    }
}
