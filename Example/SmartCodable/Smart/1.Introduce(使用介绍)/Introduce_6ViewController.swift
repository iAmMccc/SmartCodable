//
//  Introduce_6ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/12/4.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable



/// 当解析失败的时，使用当前属性初始化的值进行填充。
class Introduce_6ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict: [String: Any] = [
            "name": [:],
        ]
        
        guard let model = Model.deserialize(from: dict) else { return }
        print(model)
    }
}




extension Introduce_6ViewController {

    struct Model: SmartCodableX {
        var name: String = "-"
        var nickName: String = "帅气的小伙"
    }
}



