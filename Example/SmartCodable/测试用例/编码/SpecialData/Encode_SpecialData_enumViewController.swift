//
//  Encode_SpecialData_enumViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit



class Encode_SpecialData_enumViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a": "one",
            "b": "other"
        ]

        guard let adaptive = Model.deserialize(from: dict) else { return }
        
        smartPrint(value: adaptive)
        
        if let to = adaptive.toDictionary() {
            print(to)
        }
    }
}


extension Encode_SpecialData_enumViewController {
    struct Model: SmartCodable {
        var a: NumberType?
        var b: Sex?
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            return [
                CodingKeys.a <--- EnumTranformer(),
                CodingKeys.b <--- RelationEnumTranformer()
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
    
    struct EnumTranformer: ValueTransformable {
        
        typealias Object = NumberType
        typealias JSON = String
        
        func transformToJSON(_ value: NumberType) -> String? {
            return value.rawValue
        }
        
        func transformFromJSON(_ value: Any) -> NumberType? {
            guard let temp = value as? String else { return nil }
            return NumberType.init(rawValue: temp)
        }
    }
    
    
    
    struct RelationEnumTranformer: ValueTransformable {
        
        typealias Object = Sex
        typealias JSON = String
        
        func transformToJSON(_ value: Sex) -> String? {
            
            switch value {
            case .man:
                return "man"
            case .women:
                return "women"
            case .other(let v):
                return v
            }
        }
    
        
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
