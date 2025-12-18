//
//  Container_ArrayViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/5/20.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable

/// 兼容Int类型，只兼容String类型的int值。
class Container_ArrayViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     
        
        let dict: [String: Any] = [
            "models2": [["name": "Mccc"]],
            "models3": "123.1",
//            
            "arr2": NSNull(),
            "arr3": []
        ]
        
        let arr: [Any] = [NSNull(), 1, dict]
        
        if let feed = [Model].deserialize(from: arr) {
            smartPrint(value: feed)
        }
    }

}
extension Container_ArrayViewController {
    struct Model: SmartCodableX {
        
        var arr1: [String] = []
        var arr2: [String] = []
        var arr3: [String] = []
        
        
        var models1: [SubModel] = []
        var models2: [SubModel] = []
        var models3: [SubModel] = []
    }
    
    struct SubModel: SmartCodableX {
        var name: String = ""
    }
}
