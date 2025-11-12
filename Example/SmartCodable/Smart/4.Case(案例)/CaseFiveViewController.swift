//
//  CaseFiveViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/11/30.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation


import SmartCodableKit




class CaseFiveViewController : BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        let json = """
        {
          "data": "success",
          "message": "200"
        }
        """

        // 此时的data是一个字符串，不是字典类型。
        guard let model = ApiConmon<StringModel>.deserialize(from: json) else { return }
        print(model)
        guard let model1 = ApiConmon<String>.deserialize(from: json) else { return }
        print(model1)
        
        
        let jsonNull = """
        {
          "data": null,
          "message": "200"
        }
        """
        guard let model2 = ApiConmon<String>.deserialize(from: jsonNull) else { return }
        print(model2)

        // 此时的data是一个字符串，不是字典类型。
        guard let model3 = ApiConmon<StringModel>.deserialize(from: json) else { return }
        print(model3)
        
        
        let json1 = """
        {
          "data": {
             "name": "Mccc",
             "age": 20
          },
          "message": "200"
        }
        """
        guard let model4 = ApiConmon<DataModel>.deserialize(from: json1) else { return }
        print(model4)
        
        
        let json2 = """
        {
          "data": [
             {
               "name": "Mcccc",
               "age": 30
             },
             {
               "name": "小明",
               "age": 100
             }
          ],
          "message": "200"
        }
        """
        guard let model5 = ApiConmon<[DataModel]>.deserialize(from: json2) else { return }
        print(model5)
        
    }
}



struct StringModel: SmartCodable {
    var string: String = ""
}


struct DataModel: SmartCodable {
    var name: String = ""
    var age: Int = 0
}

struct ApiConmon<Element: Codable>: SmartCodable {
    init() { }
    
    var data: Element?
    var message: String = ""

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decode(String.self, forKey: .message)

        
        if Element.self == StringModel.self {
            if  let v  = try container.decodeIfPresent(String.self, forKey: .data) {
                self.data = StringModel(string: v) as? Element
            }
        } else {
            self.data = try container.decodeIfPresent(Element.self, forKey: .data)
        }
        
    }
}
