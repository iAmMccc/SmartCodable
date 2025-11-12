//
//  DecodingDictLogViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/8/9.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation


import SmartCodableKit


/** 日志等级 详细信息请查看 SmartSentinel类
 * 通过配置SmartSentinel.debugMode 设置日志登记
 */


/** 编码错误提示 详细信息请查看
 ========================  [Smart Decoding Log]  ========================
 Family 👈🏻 👀
    |- name    : Expected to decode String but found an array instead.
    |- location: Expected to decode String but found an array instead.
    |- date    : Expected to decode Date but found an array instead.
    |> father: Father
       |- name: Expected String value but found null instead.
       |- age : Expected to decode Int but found a string/data instead.
       |> dog: Dog
          |- hobby: Expected to decode String but found a number instead.
    |> sons: [Son]
       |- [Index 0] hobby: Expected to decode String but found a number instead.
       |- [Index 0] age  : Expected to decode Int but found a string/data instead.
       |- [Index 1] age  : Expected to decode Int but found an array instead.
 =========================================================================
 */

class DecodingDictLogViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        
//        demo()
//        demo1()
//        demo2()
//        demo3()
        demo4()
    }
    
    func demo() {
        let dict: [String: Any]? = nil
        guard let model = Family.deserialize(from: dict) else { return }
        print("model = \(model)")
    }
    
    
    func demo1() {
        let dict: [String: Any] = [:]
        guard let model = Family.deserialize(from: dict) else { return }
        print("model = \(model)")
    }
    
    func demo2() {
        let dict: [String: Any] = [
            "name": NSNull(),
            "date": NSNull(),
            "sons": NSNull(),
            "father": NSNull(),
            "location": NSNull(),
        ]
        guard let model = Family.deserialize(from: dict) else { return }
        print("model = \(model)")
    }
    
    func demo3() {
        let dict: [String: Any] = [
            "name": [],
            "date": [],
            "sons": 123,
            "father": 123,
            "location": [],
        ]
        guard let model = Family.deserialize(from: dict) else { return }
        print("model = \(model)")
    }
    
    func demo4() {
        let dict: [String: Any] = [
            "name": [],
            "date": [],
            "location": [],
            "father": [
                "name": NSNull(),
                "age": "123",
                "dog": [
                    "hobby": 123,
                ]
            ],
            "sons": [
                [
                    "hobby": 123,
                    "age": "Mccc"
                ],
                [
                    "hobby": 123,
                    "age": []
                ]
            ],
        ]
        guard let model = Family.deserialize(from: dict) else { return }
        print("model = \(model)")
    }

}


extension DecodingDictLogViewController {
    struct Family: SmartCodable {
        var name: String = "我的家"
        var location: String = ""
        var date: Date = Date()
        
        var father: Father = Father()
        var sons: [Son] = []
    }

    struct Father: SmartCodable {
        var name: String = ""
        var age: Int = 0
        var dog: Dog = Dog()
    }


    struct Son: SmartCodable {
        var hobby: String = ""
        var age: Int = 0
    }

    struct Dog: SmartCodable {
        var hobby: String = ""
    }
}



