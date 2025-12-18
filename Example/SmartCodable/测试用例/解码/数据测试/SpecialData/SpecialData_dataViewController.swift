//
//  SpecialData_dataViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import SmartCodable

class SpecialData_dataViewController: BaseCompatibilityViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     
        test()
    }

    func getStrategy() -> JSONDecoder.SmartDataDecodingStrategy {
        return .base64
    }
    
    func test() {
        let strategy = getStrategy()
        let dict = getDictData(mode: .normal, strategy: strategy)
        
        if let model = DataModel.deserialize(from: dict, options: [.data(strategy)]) {
            print(model)
            print(model.aData.toString() ?? "")
            
            print(model.toDictionary() as Any)
        }
        
        
    }
}


extension SpecialData_dataViewController {
    enum Mode {
        /// 缺少键
        case keyless
        /// 值为null
        case null
        /// 值类型错误
        case typeMismatch
        /// 正常数据
        case normal
    }
    
    
    func getDictData(mode: Mode, strategy: JSONDecoder.SmartDataDecodingStrategy) -> [String: Any] {
        switch mode {
        case .keyless:
            return [:]
        case .null:
            return [
                "aData": NSNull(),
                "bData": NSNull(),
            ]
        case .typeMismatch:
            return [
                "aData": [],
                "bData": [ : ]
            ]
        case .normal:
            return [:]
        }
    }
}



extension SpecialData_dataViewController {
    struct DataModel: SmartCodableX {
        var aData: Data = Data()
        var bData: Data?
    }
}
