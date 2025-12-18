//
//  Strength_6ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/8/14.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable

/** 枚举映射失败的情况
 * codable是自动将数据映射成枚举。
 * 通过SmartCaseDefaultable协议，兼容映射失败，返回一个默认值。
 */

class Introduce_8ViewController: BaseCompatibilityViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
    
        let dict: [String: Any] = [
//            "number": "one",
            "number1": [],
            "number2": "one",

            "sex": "haha"
        ]
        
        guard let model = CompatibleEnum.deserialize(from: dict) else { return }
        smartPrint(value: model)

        // 如果进入兼容逻辑，json值将被修改，无法恢复。
        guard let transformDict = model.toDictionary() else { return }
        print(transformDict)
    }
}


extension Introduce_8ViewController {
    
    struct CompatibleEnum: SmartCodableX {

        init() { }
        var number: NumberType = .two
        var number1: NumberType = .two
        var number2: NumberType = .two

        
        var sex: Sex = .man
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.sex <--- RelationEnumTranformer()
            ]
        }
    }
    
    enum NumberType: String, SmartCaseDefaultable {        
        case one
        case two
        case three
    }
    
    /// 关联值枚举的解析， 需要自己接管decode
    enum Sex: SmartAssociatedEnumerable {
        static let defaultCase: Sex = .man
        case man
        case women
        case other(String)
    }
}


extension Introduce_8ViewController {
    struct RelationEnumTranformer: ValueTransformable {
        func transformToJSON(_ value: Introduce_8ViewController.Sex) -> String? {
            
            switch value {
            case .man:
                return "man"
            case .women:
                return "women"
            case .other(let v):
                return v
            }
        }
        
        
        
        typealias Object = Sex
        typealias JSON = String
        
        func transformFromJSON(_ value: Any) -> Sex? {
            guard let temp = value as? String else { return .man }

            switch temp {
            case "man":
                return .man
            case "women":
                return .women
            default:
                return .other(temp)
            }
        }
    }
}


