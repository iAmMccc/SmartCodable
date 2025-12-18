//
//  Introduce_2ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/6.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable


/** 模型和json之间互相转化
 * 1. 验证 字典转模型， 此时的模型转字典。
 * 2. 验证json字符串转模型，模型转json字符串
 * 3. 验证数组字典转模型数组，数组模型转数组字典，字典数组转json字符串，json字符串转模型数组。
 */
class Introduce_2ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let dict = [
            "name": "xiaoming",
            "className": "35 class",
            "detail": ["detail": "my name is xiaoming"],
            "love": [["name": "basketball", "time": "7 years"], ["name": "football", "time": "3 years"]]
        ] as [String : Any]
        
       
        // 字典转模型
        guard let xiaoMing = JsonToModel.deserialize(from: dict) else { return }
        smartPrint(value: xiaoMing)
        /**
         JsonToModel(name: "xiaoming", className: "35 class", detail: SmartCodable_Example.JsonToModelDetail(detail: "my name is xiaoming"), love: [["time": "7 years", "name": "basketball"], ["time": "3 years", "name": "football"]])
         */
        
        
        // 模型转字典
        let studentDict = xiaoMing.toDictionary() ?? [:]
        print(studentDict)
        print("\n")
        /**
         ["detail": {
             detail = "my name is xiaoming";
         }, "className": 35 class, "love": <__NSArrayI 0x6000032fbb60>(
         {
             name = basketball;
             time = "7 years";
         },
         {
             name = football;
             time = "3 years";
         }
         )
         , "name": xiaoming]
         */
        
        
        
        // 模型转json字符串
        let json1 = xiaoMing.toJSONString(prettyPrint: true) ?? ""
        print(json1)
        print("\n")
        /**
         {
           "name" : "xiaoming",
           "className" : "35 class",
           "detail" : {
             "detail" : "my name is xiaoming"
           },
           "love" : [
             {
               "name" : "basketball",
               "time" : "7 years"
             },
             {
               "name" : "football",
               "time" : "3 years"
             }
           ]
         }
         */

        

        
        
        /** 验证数组
         * 1. 字典类型的数组，转模型数组
         * 2. 模型数组转字典数组
         * 3. 字典数组，转json字符串
         * 4. json字符串转模型数组
         */
        let arr = [dict, dict]
        guard let models = [JsonToModel].deserialize(from: arr) else { return }
        smartPrint(value: xiaoMing)

        let arrTranform = models.toArray() ?? []
        smartPrint(value: arrTranform)

        let arrJson = models.toJSONString() ?? ""
        smartPrint(value: arrJson)
    }
}

extension Introduce_2ViewController {
    struct JsonToModel: SmartCodableX {
        var name: String = ""
        var className: String = ""
        var detail: JsonToModelDetail = JsonToModelDetail()
        var love: [[String: String]] = []
        
        init() { }
    }

    struct JsonToModelDetail: SmartCodableX {
        var detail: String = ""
        
        init() { }
    }

}





