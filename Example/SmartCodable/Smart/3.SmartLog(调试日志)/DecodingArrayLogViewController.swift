//
//  DecodingArrayLogViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/4/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable

class DecodingArrayLogViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
            
//        demo()
//        demo1()
//        demo2()
//        demo3()
        demo4()
    }
    
    func demo() {
        let arr: [Any]? = nil
        guard let model = [Family].deserialize(from: arr) else { return }
        print("model = \(model)")
    }
    
    
    func demo1() {
        let arr: [Any] = []
        guard let model = [Family].deserialize(from: arr) else { return }
        print("model = \(model)")
    }
    
    func demo2() {
        let arr: [Any] = [
            [
                "name": 123,
                "date": NSNull(),
                "sons": [
                    [
                        "hobby": 123
                    ]
                ],
                "father": [
                    "name": 123,
                ],
                "location": NSNull(),
            ]
        ]
        guard let model = [Family].deserialize(from: arr) else { return }
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
            "fathers": [[
                "name": NSNull(),
                "age": "123",
                "dog": [
                    "hobby": 123,
                ],
                "dogs": [[
                    "hobby": 123,
                ]]
            ]],
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


extension DecodingArrayLogViewController {
    struct Family: SmartCodableX {
        var name: String = "我的家"
//        var location: String = ""
//        var date: Date = Date()

        var fathers: [Father] = []
        var sons: [Son] = []
    }

    struct Father: SmartCodableX {
        var name: String = ""
//        var age: Int = 0
        var dog: Dog = Dog()
        var dogs: [Dog] = []

    }


    struct Son: SmartCodableX {
        var hobby: String = ""
//        var age: Int = 0
    }

    struct Dog: SmartCodableX {
        var hobby: String = ""
    }
}



