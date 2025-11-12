//
//  ComplexDataStructureDetailModel.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/6.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

struct Class: SmartCodable {

    var name: String = ""
    var number: Int = 0
    var students: [Student] = []
    

    mutating func didFinishMapping() {
        if name.count == 0 {
            name = "未知"
        }
    }
    
    init() { }
}

struct Student: SmartCodable {
    
    var id: Int = 0
    var sex: Sex = .man
    var name: String = ""
    var area: String = ""
    
//    // 演示多定义字段的情况
    var more: String = ""
    
    init() { }
    
    mutating func didFinishMapping() {
        
        
        if area.count == 0 {
            area = "-"
        }
    }

    enum Sex: String, SmartCaseDefaultable {
        case man = "男"
        case woman = "女"
    }
}


