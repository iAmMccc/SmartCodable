//
//  SpecialData_URLViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable

class SpecialData_URLViewController: BaseCompatibilityViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// 浮点数的异常数据（Nan & inf）处理，不再提供demo。
        /// 底层将这两个值当成了字符串处理，遇到了就提供默认值。

        
        let dict: [String: Any] = [
            "a": "0",
            "b": "Mccc",
            "c": [],
            "d": NSNull(),
            "e": "www.baidu.com",
        ]
  
        
        if let model = URLModel.deserialize(from: dict) {
            smartPrint(value: model)
        }
    }
    
    struct URLModel: SmartCodableX {
        var a: URL?
        var b: URL?
        var c: URL?
        var d: URL?
        var e: URL?
    }
}



//extension URL : Codable {
//    private enum CodingKeys : Int, CodingKey {
//        case base
//        case relative
//    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let relative = try container.decode(String.self, forKey: .relative)
//        let base = try container.decodeIfPresent(URL.self, forKey: .base)
//
//        guard let url = URL(string: relative, relativeTo: base) else {
//            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
//                                                                    debugDescription: "Invalid URL string."))
//        }
//
//        self = url
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(self.relativeString, forKey: .relative)
//        if let base = self.baseURL {
//            try container.encode(base, forKey: .base)
//        }
//    }
//}


