//
//  TestViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/1.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import SmartCodable
import HandyJSON
import CleanJSON
import BTPrint


class TestViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        
//        SmartSentinel.debugMode = .none
        
        let dict1: [String: Any] = [
            "type": 1,
            "data": [
                "a": "aaaa",
                "b": 100
            ]
        ]
        
        
        let dict2: [String: Any] = [
            "type": 2,
            "data": [
                "c": "cccc",
                "d": "200"
            ]
        ]

        
        guard let model1 = Model.deserialize(from: dict1) else { return }
        print(model1.data as Any)
        
        print("\n")
        
        guard let model2 = Model.deserialize(from: dict2) else { return }
        print(model2.data as Any)
    }
    
    
    struct Model: SmartCodable {
        @SmartFlat
        var data: ModelPackage?
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.data <--- Tranformer()
            ]
        }
    }
    
    enum ModelType: Int {
        case one = 1
        case two = 2
    }
    
    enum ModelPackage: SmartAssociatedEnumerable {
        nonisolated(unsafe) static var defaultCase: ModelPackage = .one(ModelOne())
        
        case one(ModelOne)
        case two(ModelTwo)
    }
    
    
    struct ModelOne: SmartCodable {
        var a: String = ""
        var b: Int = 0
    }
    
    struct ModelTwo: SmartCodable {
        var c: String = ""
        var d: Int = 0
    }
    
    
    struct Tranformer: ValueTransformable {
        func transformFromJSON(_ value: Any) -> ModelPackage? {
            
            guard let dict = value as? [String: Any] else { return nil }
            
            guard let type: Int = dict["type"] as? Int else { return nil }
            
//            guard let typeInt: Int = Int(type) else { return nil }


            guard let modelType = ModelType(rawValue: type) else { return nil }
            
            guard let data = dict["data"] as? [String: Any] else { return nil }
            
            switch modelType {
            case .one:
                if let model = ModelOne.deserialize(from: data) {
                    return .one(model)
                }
            case .two:
                if let model = ModelTwo.deserialize(from: data) {
                    return .two(model)
                }
            }
            return nil
        }
        
        func transformToJSON(_ value: ModelPackage) -> JSON? {
            return nil
        }
        
        
        typealias Object = ModelPackage
        
        typealias JSON = Any
    }
}


