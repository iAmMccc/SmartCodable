//
//  Introduce_12ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/9/26.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import Combine
import SmartCodable

class Introduce_12ViewController: BaseViewController {
    var cancellables = Set<AnyCancellable>()
    
    var model: PublishedModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict: [String: Any] = [
            "name": [
                "a": "Mccc"
            ],
            
        ]
        
        if let model = PublishedModel.deserialize(from: dict) {
            
            self.model = model
            print("反序列化后的 name 值: \(model.name as Any)")
            
            // 正确访问 name 属性的 Publisher
            model.$name
                .sink { newName in
                    print("name 属性发生变化，新值为: \(newName  as Any)")
                }
                .store(in: &cancellables)
            
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 修改 model 的 name 属性
        model?.name = ABC()
    }
}

// 定义 PublishedModel，并实现反序列化
class PublishedModel: ObservableObject, SmartCodableX {
    required init() {}
    
    @SmartPublished
    var name: ABC?
}

struct ABC: SmartCodableX {
    var a: String = ""
}


