//
//  Encode_CustomKeyViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/7.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation


import SmartCodableKit

/** 需要测试这三种改变key映射的情况
 * 1. 通过全局策略
 * 2. 通过CodingKeys
 * 3. 通过mappingForKey
 */


class Encode_CustomKeyViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a_key": "2024-06-06",
            "bbbKey": "www.baidu.com"
        ]

        let option = SmartDecodingOption.key(.fromSnakeCase)
        guard let adaptive = Model.deserialize(from: dict, options: [option]) else { return }
        
        smartPrint(value: adaptive)
        
        if let to = adaptive.toDictionary() {
            print(to)
        }
    }
}


extension Encode_CustomKeyViewController {
    struct Model: SmartCodable {
        var aKey: Date?
        var bKey: URL?
        
        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                CodingKeys.bKey <--- "bbbKey"
            ]
        }
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            let tf = DateFormatter()
            tf.dateFormat = "yyyy-MM-dd"
            return [
                CodingKeys.aKey <--- SmartDateTransformer(strategy: .formatted(tf)),
                CodingKeys.bKey <--- SmartURLTransformer(prefix: "https://")
            ]
        }
    }
}
