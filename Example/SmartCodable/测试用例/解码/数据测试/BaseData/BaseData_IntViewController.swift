//
//  BaseData_IntViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/1.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SmartCodableKit

/// 兼容Int类型，只兼容String类型的int值。
class BaseData_IntViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     
        
        let dict: [String: Any] = [
            "int": "123",
            "int1": "123.1",
            "int2": 12.3,
            "int3": NSNull(),
            "int4": [],
            "int5": true
            
        ]
        
        guard let feed = CompatibleInt.deserialize(from: dict) else { return }
//        print(feed)
        smartPrint(value: feed)
        /**
         "CompatibleInt的属性打印信息："
         "属性：int 的类型是 Int， 其值为 123"
         "属性：int1 的类型是 Optional<Int>， 其值为 nil"
         "属性：int2 的类型是 Optional<Int>， 其值为 nil"
         "属性：int3 的类型是 Optional<Int>， 其值为 nil"
         "属性：int4 的类型是 Optional<Int>， 其值为 nil"
         "属性：int5 的类型是 Optional<Int>， 其值为 nil"
         */
    }

}

struct CompatibleInt: SmartCodable {
    var int: Int = 1
    var int1: Int?
    var int2: Int?
    var int3: Int?
    var int4: Int?
    var int5: Int = 0

    init() { }
}


