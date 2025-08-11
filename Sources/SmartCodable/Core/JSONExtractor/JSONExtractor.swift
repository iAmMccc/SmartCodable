//
//  Cachable.swift
//  SmartCodable
//
//  Created by Mccc on 2024/6/3.
//

import Foundation
struct JSONExtractor {
    
    private init() { }
    
    /// extract(from:by:) 用于从 Data/String/Dict 中提取路径内容
    static func extract(from input: Any?, by designatedPath: String?, on modelType: Any.Type) -> Any? {
        
        guard let input = input else {
            logNilValue(for: "\(type(of: input))", on: modelType)
            return nil
        }
        
        if let path = designatedPath, !path.isEmpty {
            let obj = toObject(input)
            if let inner = getInnerObject(inside: obj, by: path) {
                return inner
            } else {
                logDataExtractionFailure(forPath: designatedPath, type: Self.self)
                return nil
            }
        } else {
            return input
        }
    }
    
    private static func toObject(_ value: Any?) -> Any? {
        
        switch value {
        case let data as Data:
            return data.toObject() // 确保这里 toObject() 方法是有效且能正确处理 Data 的。
        case let json as String:
            return Data(json.utf8).toObject() // 直接使用 Data 初始化器。
        case let dict as [String: Any]:
            return dict
        case let arr as [Any]:
            return arr
        default:
            return nil
        }
    }
    
    private static func getInnerObject(inside object: Any?, by designatedPath: String?) -> Any? {
        
        var result: Any? = object
        var abort = false
        if let paths = designatedPath?.components(separatedBy: "."), paths.count > 0 {
            var next = object as? [String: Any]
            paths.forEach({ (seg) in
                if seg.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" || abort {
                    return
                }
                if let _next = next?[seg] {
                    result = _next
                    next = _next as? [String: Any]
                } else {
                    abort = true
                }
            })
        }
        return abort ? nil : result
    }
}


extension Data {
    fileprivate func toObject() -> Any? {
        let jsonObject = try? JSONSerialization.jsonObject(with: self, options: .allowFragments)
        return jsonObject
    }
    
    
    /// 将Plist Data 转成 JSON Data
    func tranformToJSONData(type: Any.Type) -> Any? {
        
        guard let jsonObject = try? PropertyListSerialization.propertyList(from: self, options: [], format: nil) else {
            SmartSentinel.monitorAndPrint(debugDescription: "Failed to convert PropertyList Data to JSON Data.", in: type)
            return nil
        }
        
        guard JSONSerialization.isValidJSONObject(jsonObject) else {
            SmartSentinel.monitorAndPrint(debugDescription: "Failed to convert PropertyList Data to JSON Data.", in: type)
            return nil
        }
        
        return jsonObject
    }
}


extension Array {
    fileprivate func toData() -> Data? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        return try? JSONSerialization.data(withJSONObject: self)
    }
}


extension Dictionary where Key == String, Value == Any {
    
    /// 确保字典中的Value类型都支持JSON序列化。
    func toData() -> Data? {
        let jsonCompatibleDict = self.toJSONCompatibleDict()
        guard JSONSerialization.isValidJSONObject(jsonCompatibleDict) else { return nil }
        return try? JSONSerialization.data(withJSONObject: jsonCompatibleDict)
    }

    private func toJSONCompatibleDict() -> [String: Any] {
        var jsonCompatibleDict: [String: Any] = [:]
        for (key, value) in self {
            jsonCompatibleDict[key] = convertToJSONCompatible(value: value)
        }
        return jsonCompatibleDict
    }
    
    /// 目前只处理了Data类型。如有需要可以继续扩展补充。
    private func convertToJSONCompatible(value: Any) -> Any {
        if let data = value as? Data {
            return data.base64EncodedString()
        } else if let dict = value as? [String: Any] {
            return dict.toJSONCompatibleDict()
        } else if let array = value as? [Any] {
            return array.map { convertToJSONCompatible(value: $0) }
        } else {
            return value
        }
    }
}
fileprivate func logNilValue(for valueType: String, on modelType: Any.Type) {
    SmartSentinel.monitorAndPrint(debugDescription: "Decoding \(modelType) failed because input \(valueType) is nil.", in: modelType)
}

fileprivate func logDataExtractionFailure(forPath path: String?, type: Any.Type) {
    
    SmartSentinel.monitorAndPrint(debugDescription: "Decoding \(type) failed because it was unable to extract valid data from path '\(path ?? "nil")'.", in: type)
}
