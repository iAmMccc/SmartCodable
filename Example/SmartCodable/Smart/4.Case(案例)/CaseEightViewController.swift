//
//  CaseEightViewController.swift
//  SmartCodable_Example
//
//  Created by qixin on 2025/7/24.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import SmartCodable

class CaseEightViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

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
                "d": 200
            ]
        ]

        
        guard let modelPackage1 = Model.deserialize(from: dict1) else { return }
        if let model = modelPackage1.model as? ModelPackage.One {
            print(model.a, model.b)

        }
        
        guard let modelPackage2 = Model.deserialize(from: dict2) else { return }
        if let model = modelPackage2.model as? ModelPackage.Two {
            print(model.c, model.d)
        }
    }
    
    
    struct Model: SmartCodable {
        /// 使用SmartFlat向上取值，内部可以获取到type 和 data层级的数据，通过type判断，进行data的区分解析。
        @SmartFlat
        private var data: ModelPackage?
        
        
        var model: Any? {
            data?.model
        }
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.data <--- Tranformer()
            ]
        }
    }
}

extension CaseEightViewController {
    /// 使用DataPackage处理不同的Model类型。
    enum ModelPackage: SmartAssociatedEnumerable {
        nonisolated(unsafe) static var defaultCase: ModelPackage = .one(One())
        
        case one(One)
        case two(Two)
        
        var model: Any {
            switch self {
            case .one(let model): return model
            case .two(let model): return model
            }
        }
        
        
        struct One: SmartCodable {
            var a: String = ""
            var b: Int = 0
        }
        
        struct Two: SmartCodable {
            var c: String = ""
            var d: Int = 0
        }
    }
}

extension CaseEightViewController {
    struct Tranformer: ValueTransformable {
        
        enum ModelType: Int {
            case one = 1
            case two = 2
        }
        
        func transformFromJSON(_ value: Any) -> ModelPackage? {
            
            guard let dict = value as? [String: Any] else { return nil }
            
            guard let type: Int = dict["type"] as? Int else { return nil }
            

            guard let modelType = ModelType(rawValue: type) else { return nil }
            
            guard let data = dict["data"] as? [String: Any] else { return nil }
            
            print(data)
            
            switch modelType {
            case .one:
                if let model = ModelPackage.One.deserialize(from: data) {
                    return .one(model)
                }
            case .two:
                if let model = ModelPackage.Two.deserialize(from: data) {
                    return .two(model)
                }
            }
            return nil
        }
        
        func transformToJSON(_ value: ModelPackage) -> JSON? {
            
            // do something
            
            return nil
        }
        
        
        typealias Object = ModelPackage
        
        typealias JSON = Any
    }
}


