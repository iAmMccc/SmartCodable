//
//  CaseTwoViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/10/27.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable


class CaseTwoViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // 这三个模型都有共同的字段（name 和 age）
        let dict: [String: Any] = [
            "name": "Mccc",
            "age": 20,
            "firstSon": [
                "hobby": "sleep",
                "name": "QiQi",
                "age": 3,
            ],
            "secondSon": [
                "height": 95.3,
                "name": "LinLin",
                "age": 3,
            ]
        ]

        guard let model = BigModel.deserialize(from: dict) else { return }
        print(model.name)
        print(model.age)
        
        print("\n")
        
        print(model.firstSon?.name ?? "")
        print(model.firstSon?.age ?? 0)
        print(model.firstSon?.hobby ?? "")
        
        print("\n")
        
        print(model.secondSon?.name ?? "")
        print(model.secondSon?.age ?? 0)
        print(model.secondSon?.height ?? 0)
        
        print("\n")
    }
}

extension CaseTwoViewController {
    class BaseModel: SmartCodableX {
        var name: String = ""
        var age: Int = 0
        
        
        private enum BaseCodingKeys: CodingKey {
            case name
            case age
        }
        
        required init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<BaseCodingKeys> = try decoder.container(keyedBy: BaseCodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.age = try container.decode(Int.self, forKey: .age)
        }
        
        required init() { }
    }
    
    class BigModel: BaseModel {
        var firstSon: FirstModel?
        var secondSon: SecondModel?
        
        private enum BigCodingKeys: CodingKey {
            case firstSon
            case secondSon
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            
            let container = try decoder.container(keyedBy: BigCodingKeys.self)
            firstSon = try container.decode(FirstModel.self, forKey: .firstSon)
            secondSon = try container.decode(SecondModel.self, forKey: .secondSon)
        }
        
        required init() {
            super.init()
        }
    }
    
    class FirstModel: BaseModel {
        var hobby: String = ""
        private enum FirsCodingKeys: CodingKey {
            case hobby
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            
            let container = try decoder.container(keyedBy: FirsCodingKeys.self)
            hobby = try container.decode(String.self, forKey: .hobby)
        }
        
        required init() {
            super.init()
        }
        
    }
    
    class SecondModel: BaseModel {
        var height: Double = 0
        
        private enum SecCodingKeys: CodingKey {
            case height
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            
            let container = try decoder.container(keyedBy: SecCodingKeys.self)
            height = try container.decode(Double.self, forKey: .height)
        }
        
        required init() {
            super.init()
        }
    }
}

