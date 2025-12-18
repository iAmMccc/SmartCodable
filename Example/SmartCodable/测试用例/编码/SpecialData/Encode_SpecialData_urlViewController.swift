//
//  Encode_SpecialData_urlViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable



class Encode_SpecialData_urlViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a": "www.baidu.com",
            "b": "https://www.baidu.com"
        ]

        guard let adaptive = Model.deserialize(from: dict) else { return }
        
        smartPrint(value: adaptive)
        
        if let to = adaptive.toDictionary() {
            print(to)
        }
    }
}


extension Encode_SpecialData_urlViewController {
    struct Model: SmartCodableX {
        var a: URL?
        var b: URL?
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            return [
                CodingKeys.a <--- SmartURLTransformer(prefix: "https://")
            ]
        }
    }
}
