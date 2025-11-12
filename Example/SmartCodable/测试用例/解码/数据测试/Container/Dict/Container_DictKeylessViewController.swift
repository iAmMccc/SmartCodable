//
//  Container_DictKeylessViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/1.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SmartCodableKit


/// 键缺失的兼容，使用默认值填充
class Container_DictKeylessViewController: BaseCompatibilityViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let json = keylssJson
        
        explicitType(json: json)
        
        print("\n\n")
        
//        optionalType(json: json)
    }
}




extension Container_DictKeylessViewController {
    /// 明确类型
    func explicitType(json: String) {
        guard let person = CompatibleTypes.deserialize(from: json) else { return }
        print("非可选属性")
        let mirr = Mirror(reflecting: person)
        for (key, value) in mirr.children {
            printValueType(key: key!, value: value)
        }

        
        /**
         "属性：a 的类型是 String， 其值为 "
         "属性：b 的类型是 Bool， 其值为 false"
         "属性：c 的类型是 Date， 其值为 2001-01-01 00:00:00 +0000"
         "属性：d 的类型是 Data， 其值为 0 bytes"
         "属性：e 的类型是 Double， 其值为 0.0"
         "属性：f 的类型是 Float， 其值为 0.0"
         "属性：g 的类型是 CGFloat， 其值为 0.0"
         "属性：h 的类型是 Int， 其值为 0"
         "属性：i 的类型是 Int8， 其值为 0"
         "属性：j 的类型是 Int16， 其值为 0"
         "属性：k 的类型是 Int32， 其值为 0"
         "属性：l 的类型是 Int64， 其值为 0"
         "属性：m 的类型是 UInt， 其值为 0"
         "属性：n 的类型是 UInt8， 其值为 0"
         "属性：o 的类型是 UInt16， 其值为 0"
         "属性：p 的类型是 UInt32， 其值为 0"
         "属性：q 的类型是 UInt64， 其值为 0"
         "属性：v 的类型是 Array<String>， 其值为 []"
         "属性：w 的类型是 Dictionary<String, Dictionary<String, Int>>， 其值为 [:]"
         "属性：x 的类型是 Dictionary<String, String>， 其值为 [:]"
         "属性：y 的类型是 Dictionary<String, Int>， 其值为 [:]"
         "属性：z 的类型是 CompatibleItem， 其值为 CompatibleItem(name: \"\", age: 0)"
         */
    }
}



extension Container_DictKeylessViewController {
    /// 可选类型
    func optionalType(json: String) {
        guard let person = OptionalCompatibleTypes.deserialize(from: json) else { return }
        
        print("可选属性")
        let mirr = Mirror(reflecting: person)
        for (key, value) in mirr.children {
            printValueType(key: key!, value: value)
        }
        
        /**
         "属性：a 的值为nil"
         "属性：b 的值为nil"
         "属性：c 的值为nil"
         "属性：d 的值为nil"
         "属性：e 的值为nil"
         "属性：f 的值为nil"
         "属性：g 的值为nil"
         "属性：h 的值为nil"
         "属性：i 的值为nil"
         "属性：j 的值为nil"
         "属性：k 的值为nil"
         "属性：l 的值为nil"
         "属性：m 的值为nil"
         "属性：n 的值为nil"
         "属性：o 的值为nil"
         "属性：p 的值为nil"
         "属性：q 的值为nil"
         "属性：v 的值为nil"
         "属性：w 的值为nil"
         "属性：x 的值为nil"
         "属性：y 的值为nil"
         "属性：z 的值为nil"
         */
    }
}


