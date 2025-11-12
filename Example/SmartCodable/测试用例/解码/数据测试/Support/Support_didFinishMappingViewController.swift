//
//  Support_didFinishMappingViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import SmartCodable

class Support_didFinishMappingViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     

//        单层字典的测试()
//        多层字典的测试()
//        字典中嵌套数组的测试()
        数组嵌套字典的测试()
    }

    
    func 单层字典的测试() {
        
        let dict = [
            "name": "睡觉"
        ]
        
        if let model = HobbyModel.deserialize(from: dict) {
            smartPrint(value: model)
        }
        
        if let model = HobbyClassModel.deserialize(from: dict) {
            smartPrint(value: model)
        }
    }
    
    func 多层字典的测试() {
        let dict: [String: Any] = [
            "name": "Mccc",
            "hobby": [
                "name": "睡觉"
            ],
            "optionalHobby": [
                "name": "打游戏"
            ]
        ]
        
        if let model = PersonModel.deserialize(from: dict) {
            smartPrint(value: model)
        }
        
        if let model = PersonClassModel.deserialize(from: dict) {
            smartPrint(value: model)
        }
    }
    
    func 字典中嵌套数组的测试() {
        let dict: [String: Any] = [
            "hobbys": [
                [
                    "name": "睡觉1"
                ]
            ],
            "optionalHobbys": [
                [
                    "name": "睡觉1"
                ],
                [
                    "name": "睡觉2"
                ]
            ]
        ]
        
        if let model = HobbysModel.deserialize(from: dict) {
            smartPrint(value: model)
        }
        
//        if let model = HobbysClassModel.deserialize(from: dict) {
//            smartPrint(value: model)
//        }
    }
    
    func 数组嵌套字典的测试() {
        let arr = [
            [
                "hobbys": [
                    [
                        "name": "睡觉1",
                    ],
                    [
                        "name": "睡觉2",
                    ]
                ],
            ]
        ]
        
        guard let models = [HobbysModel].deserialize(from: arr) else { return }
        smartPrint(value: models)
    }
}


extension Support_didFinishMappingViewController {
    struct HobbysModel: SmartCodableX {
        var hobbys: [HobbyModel] = []
        var optionalHobbys: [HobbyModel]?
    }
    
    class HobbysClassModel: SmartCodableX {
        var hobbys: [HobbyClassModel] = []
        var optionalHobbys: [HobbyClassModel]?

        required init() { }


    }
}

extension Support_didFinishMappingViewController {
    struct PersonModel: SmartCodableX {
        var name: String = ""
        var hobby = HobbyModel()
        var optionalHobby: HobbyModel?


        mutating func didFinishMapping() {
            name = "我是" + name
        }
    }
    
    class PersonClassModel: SmartCodableX {
        var name: String?
        var hobby = HobbyModel()
        var optionalHobby: HobbyClassModel?

        func didFinishMapping() {
            name = "我是" + (name ?? "无名者")
        }
        
        required init() { }
    }
}

extension Support_didFinishMappingViewController {
    struct HobbyModel: SmartCodableX {
        var name: String = ""

        mutating func didFinishMapping() {
            name = "我的爱好是" + name
        }
    }
    
    class HobbyClassModel: SmartCodableX {
        var name: String = ""
        
        required init() { }
        
        
        func didFinishMapping() {
            name = "我的爱好是" + name
        }
    }
}
