//
//  Introduce_7ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/12/4.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

/// 内部会解析有结构的json字符串到模型上
class Introduce_7ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict: [String: Any] = [
            "hobby": "{\"name\":\"sleep1\"}",
            "hobbys": "[{\"name\":\"sleep2\"}]",
        ]
        
        guard let model = Model.deserialize(from: dict) else { return }
        print(model)
    }
}




extension Introduce_7ViewController {

    struct Model: SmartCodable {
        var hobby: Hobby?
        var hobbys: [Hobby]?
    }
    
    struct Hobby: SmartCodable {
        var name: String = ""
    }
}



