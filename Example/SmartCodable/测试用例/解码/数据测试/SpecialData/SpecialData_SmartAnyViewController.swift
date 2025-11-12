//
//  SpecialData_SmartAnyViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

class SpecialData_SmartAnyViewController: BaseCompatibilityViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict: [String: Any] = [

            "single_b": NSNull(),
            "single_c": ["abc": "Test"],
            "single_d": 123,
            
            "single_f": NSNull(),
            "single_g": ["abc": "Test"],
            "single_h": 123,
            
            
            "dict_b": NSNull(),
            "dict_c": 123,
            "dict_d": ["abc": 123],
            
            "dict_f": NSNull(),
            "dict_g": 123,
            "dict_h": ["abc": true],
            
            
            "arr_b": NSNull(),
            "arr_c": 123,
            "arr_d": [123],
            
            "arr_f": NSNull(),
            "arr_g": 123,
            "arr_h": ["abc"],
            
            "complex": [
                "a": [
                    "a": true,
                    "b": "mccc",
                    "c": 1.1
                ]
            ]
        ]

        if let model = DictModel.deserialize(from: dict) {
            smartPrint(value: model)
            
            print(model.complex)
        }
    }
}


extension SpecialData_SmartAnyViewController {
    struct DictModel: SmartCodable {
        
        @SmartAny
        var complex: [String: Any] = [:]
        @SmartAny
        var single_a: Any?
        @SmartAny
        var single_b: Any?
        @SmartAny
        var single_c: Any?
        @SmartAny
        var single_d: Any?

        @SmartAny
        var single_e: Any = "single_e"
        @SmartAny
        var single_f: Any = "single_f"
        @SmartAny
        var single_g: Any = "single_g"
        @SmartAny
        var single_h: Any = "single_h"

        @SmartAny
        var dict_a: [String: Any]?
        @SmartAny
        var dict_b: [String: Any]?
        @SmartAny
        var dict_c: [String: Any]?
        @SmartAny
        var dict_d: [String: Any]?
        
        @SmartAny
        var dict_e: [String: Any] = [:]
        @SmartAny
        var dict_f: [String: Any] = [:]
        @SmartAny
        var dict_g: [String: Any] = [:]
        @SmartAny
        var dict_h: [String: Any] = [:]
        
        @SmartAny
        var arr_a: [Any]?
        @SmartAny
        var arr_b: [Any]?
        @SmartAny
        var arr_c: [Any]?
        @SmartAny
        var arr_d: [Any]?

        @SmartAny
        var arr_e: [Any] = []
        @SmartAny
        var arr_f: [Any] = []
        @SmartAny
        var arr_g: [Any] = []
        @SmartAny
        var arr_h: [Any] = []
    }
}
