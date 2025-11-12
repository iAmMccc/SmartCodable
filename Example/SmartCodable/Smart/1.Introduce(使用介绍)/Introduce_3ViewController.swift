//
//  Introduce_3ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/6.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

import SmartCodableKit


/** 模型数组和json之间互相转化
 * 1. 验证 字典转模型， 此时的模型转字典。
 * 2. 验证json字符串转模型，模型转json字符串
 * 3. 验证数组字典转模型数组，数组模型转数组字典，字典数组转json字符串，json字符串转模型数组。
 */
class Introduce_3ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict = [
            "name": "xiaoming",
            "className": "35 class",
            "detail": ["detail": "my name is xiaoming"],
            "love": [["name": "basketball", "time": "7 years"], ["name": "football", "time": "3 years"]]
        ] as [String : Any]
        
        let arr = [dict, dict]


        
        /** 验证数组
         * 1. 字典类型的数组，转模型数组
         * 2. 模型数组转字典数组
         * 3. 字典数组，转json字符串
         * 4. json字符串转模型数组
         */
        
        // 数组转模型数组
        guard let models = [ArrayAndModels].deserialize(from: arr) else { return }
        print(models)
        /**
         [returnArrayAndModels(name: "xiaoming", className: "35 class", detail: returnArrayAndModelsDetail(detail: "my name is xiaoming"), love: [["name": "basketball", "time": "7 years"], ["name": "football", "time": "3 years"]]), returnArrayAndModels(name: "xiaoming", className: "35 class", detail: returnArrayAndModelsDetail(detail: "my name is xiaoming"), love: [["time": "7 years", "name": "basketball"], ["name": "football", "time": "3 years"]])]
         */

        // 数组模型转数组
        let arrTranform = models.toArray() ?? []
        print(arrTranform)
        /**
         [{
             className = "35 class";
             detail =     {
                 detail = "my name is xiaoming";
             };
             love =     (
                         {
                     name = basketball;
                     time = "7 years";
                 },
                         {
                     name = football;
                     time = "3 years";
                 }
             );
             name = xiaoming;
         }, {
             className = "35 class";
             detail =     {
                 detail = "my name is xiaoming";
             };
             love =     (
                         {
                     name = basketball;
                     time = "7 years";
                 },
                         {
                     name = football;
                     time = "3 years";
                 }
             );
             name = xiaoming;
         }]

         */

        
        
        // 数组模型转json字符串
        let arrJson = models.toJSONString() ?? ""
        print(arrJson)
        /**
         [{"className":"35 class","detail":{"detail":"my name is xiaoming"},"name":"xiaoming","love":[{"name":"basketball","time":"7 years"},{"name":"football","time":"3 years"}]},{"className":"35 class","detail":{"detail":"my name is xiaoming"},"name":"xiaoming","love":[{"name":"basketball","time":"7 years"},{"name":"football","time":"3 years"}]}]
         */
    }
}


extension Introduce_3ViewController {
    struct ArrayAndModels: SmartCodable {
        var name: String = ""
        var className: String = ""
        var detail = ArrayAndModelsDetail()
        var love: [[String: String]] = []
        
        init() { }
    }

    struct ArrayAndModelsDetail: SmartCodable {
        var detail: String = ""
        
        init() { }
    }

}

