//
//  TestViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/1.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import SmartCodable
import HandyJSON
import CleanJSON
import BTPrint



/** 5.1.0更新日志
 1. 重构数据转换方式，抛弃`JSONParser`，使用官方的`JSONSerialization`。让解析更安全。
 2. 明确 `DecodingCache` 和 `EncodingCache` 的路径是当前 `Container` 的 `codingPath`，通过key在其中寻找对应的初始化值或值解析器。
 3. 梳理并优化值解析器逻辑。
 4. `@IgnoredKey` 更名为 `@SmartIgnored`.
 5. 优化 `CGFloat` 解析逻辑，`CGFloat` 在解析中是一个复合容器，可以划归跟`URL`、`Date`同样的处理方式。
 */


class TestViewController: BaseViewController {
    
    var object: [Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let data = areaJSON()
        
        object = data.toArray()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let start = CFAbsoluteTimeGetCurrent()

        guard let objects = [AreaSmart].deserialize(from: object) else {
            return
        }
        let end = CFAbsoluteTimeGetCurrent()
        print("⏱ 方法耗时: \(end - start) 秒")
        
    }
    

    

}
func areaJSON() -> Data {
    let resource = "10000"
    let url = Bundle.main.url(forResource: resource, withExtension: "json")
    guard let url = url,
        let data = try? Data(contentsOf: url) else {
            fatalError()
    }
    return data
}
// SmartCodable
struct AreaSmart: SmartCodable {
    
    
    var areaCode: String = ""
    var name: String = ""
    var city: [City] = []
    
    struct City: SmartCodable {
        var name: String = ""
        var areaCode: String = ""
        var district: [District] = []
        
        struct District: SmartCodable {
            var name: String = ""
            var areaCode: String = ""
        }
    }
}


extension Data {
    /// 尝试将 Data 解析为 JSON 对象（字典或数组）
    func toJSONObject() -> Any? {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [])
            return json
        } catch {
            print("JSON 解析失败: \(error)")
            return nil
        }
    }
}
fileprivate func jsonData(from object: Any?, prettyPrinted: Bool = false) -> Data? {
    
    guard let object = object else { return nil }
    
    guard JSONSerialization.isValidJSONObject(object) else {
        print("⚠️ 无法转成 JSON：不是合法的 JSON 对象")
        return nil
    }
    let options: JSONSerialization.WritingOptions = prettyPrinted ? .prettyPrinted : []
    return try? JSONSerialization.data(withJSONObject: object, options: options)
}
