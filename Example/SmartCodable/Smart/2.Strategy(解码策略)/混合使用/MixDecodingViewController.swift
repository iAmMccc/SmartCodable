//
//  MixDecodingViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/28.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable


/** 混合使用各种解析策略
 * 1. 忽略key的解析
 * 2. 全部的key映射关系
 * 3. 局部的key映射关系
 * 4. 全局的Value映射关系
 * 5. 局部的Value映射关系
 * 6. 解码完成的回调
 */
class MixDecodingViewController: BaseViewController {

    var model: SmartModel?
    override func viewDidLoad() {
        super.viewDidLoad()

        let dict1: [String: Any] = [
            "date": "2024-04-07",
            "Url": "www.baidu.com",
            "ignoreKey": "忽略我",
            "sub": [
                "subDate": 1712491290,
                "subColor": "7DA5E3",
                "subData": "aHR0cHM6Ly93d3cucWl4aW4uY29t"
            ]
        ]
        
        let option: SmartDecodingOption = .key(.firstLetterLower)
        
        guard let model = SmartModel.deserialize(from: dict1, options: [option]) else { return }
        print(model)
//        if let data = model.data, let url = String(data: data, encoding: .utf8) {
//            print(url)
//            // https://www.qixin.com
//        }
    }
}


extension MixDecodingViewController {
    
    struct SmartModel: SmartCodableX {
        
//        var ignoreKey: String?

        
        var date1: Date?
//        var date2: Date?
//        var data: Data?
//        var url: URL?
//        @SmartHexColor
//        var color: UIColor?

        // case 1 【解析前】：解析忽略
//        enum CodingKeys: CodingKey {
//            // 忽略ignoreKey的解析
//            //  case ignoreKey
//            case date1
//            case date2
//            case data
//            case url
//            case color
//        }
        
        // case 2 【解析中】： key的映射关系
        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                CodingKeys.date1 <--- ["date", "date1"],
//                CodingKeys.date2 <--- "sub.subDate",
//                CodingKeys.color <--- "sub.subColor",
//                CodingKeys.data <--- "sub.subData"
            ]
        }
        
        // case 3 【解析中】： value的解析策略
//        static func mappingForValue() -> [SmartValueTransformer]? {
//            let format = DateFormatter()
//            format.dateFormat = "yyyy-MM-dd"
//            return [
//                CodingKeys.url <--- SmartURLTransformer(prefix: "https://"),
//                CodingKeys.date1 <--- SmartDateFormatTransformer(format),
//                CodingKeys.date2 <--- SmartDateTransformer(),
//                CodingKeys.data <--- SmartDataTransformer()
//            ]
//        }
        
        // case 4 【解析后】： 进行自定义的数据处理
//        mutating func didFinishMapping() {
//            ignoreKey = "手动赋值"
//        }
    }
}
