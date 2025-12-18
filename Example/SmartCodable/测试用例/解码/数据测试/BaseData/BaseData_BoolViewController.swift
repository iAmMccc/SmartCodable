//
//  BaseData_BoolViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/1.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SmartCodable


/// 对Bool类型进行兼容
/// int类型：   0会被转义为false， 1会被转义为true，其他值会被抛弃
/// sting类型： true / false / no / yes 以及对应的大小的情况，转义成Bool值。
class BaseData_BoolViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                

        guard let adaptive = BoolAdaptive.deserialize(from: getBoolAdaptiveData()) else { return }
        
        smartPrint(value: adaptive)

        
        /**
         "属性：a 的类型是 Bool， 其值为 false"
         "属性：b 的类型是 Bool， 其值为 true"
         "属性：c 的类型是 Bool， 其值为 false"
         "属性：d 的类型是 Bool， 其值为 true"


         "属性：e 的类型是 Bool， 其值为 true"
         "属性：f 的类型是 Bool， 其值为 true"
         "属性：g 的类型是 Bool， 其值为 true"
         "属性：h 的类型是 Bool， 其值为 true"
         "属性：i 的类型是 Bool， 其值为 true"
         "属性：j 的类型是 Bool， 其值为 true"


         "属性：k 的类型是 Bool， 其值为 false"
         "属性：l 的类型是 Bool， 其值为 false"
         "属性：m 的类型是 Bool， 其值为 false"
         "属性：n 的类型是 Bool， 其值为 false"
         "属性：o 的类型是 Bool， 其值为 false"
         "属性：p 的类型是 Bool， 其值为 false"
         "属性：q 的类型是 Bool， 其值为 false"
         "属性：r 的类型是 Bool， 其值为 false"
         */
    }
}


extension BaseData_BoolViewController {
    func getBoolAdaptiveData() -> [String: Any] {
        let dict = [
            "a": 0,
            "b": 1,
            "c": "0",
            "d": "1",
            
            "e": "YES",
            "f": "Yes",
            "g": "yes",
            "h": "True",
            "i": "true",
            "j": "TRUE",
            
            "k": "NO",
            "l": "No",
            "m": "no",
            "n": "FALSE",
            "o": "False",
            "p": "false",
            "q": "ABC",
            "r": 234,
        ] as [String : Any]
        
        return dict
    }
    
    struct BoolAdaptive: SmartCodableX {
        init() { }
        
        var a: Bool?
        var b: Bool = false
        var c: Bool = false
        var d: Bool = false

        var e: Bool = false
        var f: Bool = false
        var g: Bool = false

        var h: Bool = false
        var i: Bool = false
        var j: Bool = false
        var k: Bool = false
        var l: Bool = false
        var m: Bool = false
        var n: Bool = false
        var o: Bool = false
        var p: Bool = false
        var q: Bool = false
        var r: Bool?
    }
}




