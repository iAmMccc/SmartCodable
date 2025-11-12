//
//  Container_unKeyedViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/7/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

/// 兼容Int类型，只兼容String类型的int值。
class Container_unKeyedViewController: BaseViewController {

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

        
//        let dict4 = getDict4()
//        guard let feed4 = Model4.deserialize(from: dict4) else { return }
//        smartPrint(value: feed4)
        
        let dict5 = getDict5()
        guard let feed5 = Model5.deserialize(from: dict5) else { return }
        smartPrint(value: feed5)
    }

}

/// 验证是unkeyedcontainer容器是数组的情况
extension Container_unKeyedViewController {
    
    func getDict1() -> [String: Any] {
        return [
            "arr2": NSNull(),
            "arr3": 123,
            "arr4": [1, "2", 3],
            "arr5": [1, "2", 3, NSNull()],
            
            "arr7": NSNull(),
            "arr8": 123,
            "arr9": [1, "2", 3],
            "arr10": [1, "2", 3, NSNull()],
        ]
    }
    
    
    struct Model1: SmartCodable {
        
        // 无key
        var arr1: [String] = []
        // 值为null
        var arr2: [String] = []
        // 值类型错误
        var arr3: [String] = []
        // 元素类型支持类型转换，如果转换失败，则返回初始化值
        var arr4: [String] = []
        var arr5: [String] = []

        
        
        var arr6: [String]?
        var arr7: [String]?
        var arr8: [String]?
        var arr9: [String]?
        var arr10: [String]?
    }
}

/// 验证是unkeyedcontainer容器是数组的情况
extension Container_unKeyedViewController {
    
    func getDict2() -> [String: Any] {
        return [
            "arr2": NSNull(),
            "arr3": 123,
            "arr4": [1, "2", 3],
            "arr5": [1, "2", 3, NSNull()],

            "arr7": NSNull(),
            "arr8": 123,
            "arr9": [1, "2", 3],
            "arr10": [1, "2", 3, NSNull()],
        ]
    }
    

    
    struct Model2: SmartCodable {
        
        // 无key
        var arr1: [String?] = []
        // 值为null
        var arr2: [String?] = []
        // 值类型错误
        var arr3: [String?] = []
        // 元素类型支持类型转换，如果转换失败，则返回初始化值
        var arr4: [String?] = []
        var arr5: [String?] = []

        
        var arr6: [String?]?
        var arr7: [String?]?
        var arr8: [String?]?
        var arr9: [String?]?
        var arr10: [String?]?

    }
}

/// 验证是unkeyedcontainer容器是[Model]的情况
extension Container_unKeyedViewController {
    
    func getDict3() -> [String: Any] {
        return [
            "arr2": NSNull(),
            "arr3": 123,
            "arr4": [["name": "Mccc", "age": "20"]],
            "arr5": [["name": "Mccc", "age": "20"], NSNull()],

            "arr7": NSNull(),
            "arr8": 123,
            "arr9": [["name": "Mccc", "age": "20"]],
            "arr10": [["name": "Mccc", "age": "20"], NSNull()],

        ]
    }
    

    
    struct Model3: SmartCodable {
        
        // 无key
        var arr1: [SubModel] = []
        // 值为null
        var arr2: [SubModel] = []
        // 值类型错误
        var arr3: [SubModel] = []
        // 元素类型支持类型转换，如果转换失败，则返回初始化值
        var arr4: [SubModel] = []
        var arr5: [SubModel] = []

        
        var arr6: [SubModel]?
        var arr7: [SubModel]?
        var arr8: [SubModel]?
        var arr9: [SubModel]?
        var arr10: [SubModel]?

    }
    
    struct SubModel: SmartCodable {
        var name: String = ""
        var age: Int?
    }
}

/// 验证是unkeyedcontainer容器是[Model]的情况
extension Container_unKeyedViewController {
    
    func getDict4() -> [String: Any] {
        return [
            "arr2": NSNull(),
            "arr3": 123,
            "arr4": [["name": "Mccc", "age": "20"]],
            "arr5": [["name": "Mccc", "age": "20"], NSNull()],
            
            "arr7": NSNull(),
            "arr8": 123,
            "arr9": [["name": "Mccc", "age": "20"]],
            "arr10": [["name": "Mccc", "age": "20"], NSNull()],
            
        ]
    }
        
    struct Model4: SmartCodable {
        
        // 无key
        var arr1: [SubModel?] = []
        // 值为null
        var arr2: [SubModel?] = []
        // 值类型错误
        var arr3: [SubModel?] = []
        // 元素类型支持类型转换，如果转换失败，则返回初始化值
        var arr4: [SubModel?] = []
        var arr5: [SubModel?] = []
        
        var arr6: [SubModel?]?
        var arr7: [SubModel?]?
        var arr8: [SubModel?]?
        var arr9: [SubModel?]?
        var arr10: [SubModel?]?
    }
}

/// 验证是unkeyedcontainer容器 SmartAny 修饰的情况
extension Container_unKeyedViewController {
    
    func getDict5() -> [String: Any] {
        return [
//            "arr2": NSNull(),
//            "arr3": 123,
//            "arr4": [1, 2, "3"],
            "arr5": ["3", NSNull()],
//            
//            "arr7": NSNull(),
//            "arr8": 123,
//            "arr9": [1, 2, "3"],
//            "arr10": ["3", NSNull()],
        ]
    }
        
    struct Model5: SmartCodable {
        
//        // 无key
//        @SmartAny
//        var arr1: [Any] = []
//        // 值为null
//        @SmartAny
//        var arr2: [Any] = []
//        // 值类型错误
//        @SmartAny 
//        var arr3: [Any] = []
//        // 元素类型支持类型转换，如果转换失败，则返回初始化值
//        @SmartAny
//        var arr4: [Any] = []
        @SmartAny
        var arr5: [String] = []
//        
//        @SmartAny
//        var arr6: [Any]?
//        @SmartAny
//        var arr7: [Any]?
//        @SmartAny
//        var arr8: [Any]?
//        @SmartAny
//        var arr9: [Any]?
//        @SmartAny
//        var arr10: [String?]?
        
    }
}
