//
//  Encode_ContainerDictViewcontroller.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/7.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SmartCodableKit


class Encode_ContainerDictViewcontroller: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let jsonStr = """
        {
            "age": "18",
            "weight": "65.4",
            "sex": "1"
        }
        """
        if let model = FeedModel.deserialize(from: jsonStr) {
            smartPrint(value: model)
        }
    }
    //模型
    struct FeedModel: SmartCodable {
        var dict: [String: String] = [:]
        var optionalDict: [String: String]?
    }
}
