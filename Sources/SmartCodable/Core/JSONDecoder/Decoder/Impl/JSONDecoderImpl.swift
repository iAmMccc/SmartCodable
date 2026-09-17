//
//  JSONDecoderImpl.swift
//  SmartCodable
//
//  Created by Mccc on 2024/5/17.
//

import Foundation


struct JSONDecoderImpl {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    let json: JSONValue
    let options: SmartJSONDecoder._Options

    /// 当前视图绑定的模型上下文；nil 表示该视图不拥有任何模型的字段表。
    /// 子模型的活动不会改变父视图的归属。
    let modelSnapshot: DecodingSnapshot?

    /// 当前视图对应的宿主属性边（宿主模型上下文 + 规范属性 key）；
    /// nil 表示没有明确的宿主属性（顶层、数组元素、字典数据键、原始嵌套结构等）。
    let propertyContext: PropertyDecodingContext?

    init(userInfo: [CodingUserInfoKey: Any],
         from json: JSONValue,
         codingPath: [CodingKey],
         options: SmartJSONDecoder._Options,
         modelSnapshot: DecodingSnapshot? = nil,
         propertyContext: PropertyDecodingContext? = nil) {
        self.userInfo = userInfo
        self.codingPath = codingPath
        self.json = json
        self.options = options
        self.modelSnapshot = modelSnapshot
        self.propertyContext = propertyContext
    }

    /// 保持数据位置（json / codingPath / userInfo / options），只替换上下文的新视图。
    ///
    /// 通过构造新 struct 完成，不修改任何共享对象上的指针；
    /// 传入 nil 是明确的隔离结果，不是“再从父级找一份”的信号。
    func replacingContexts(
        model: DecodingSnapshot?,
        property: PropertyDecodingContext?
    ) -> JSONDecoderImpl {
        JSONDecoderImpl(
            userInfo: userInfo,
            from: json,
            codingPath: codingPath,
            options: options,
            modelSnapshot: model,
            propertyContext: property
        )
    }
}


// Regarding the generation of containers, there is no need for compatibility,
// when the type is wrong, an exception is thrown,
// and when the exception is handled, the initial value can be obtained.
extension JSONDecoderImpl: Decoder {
    func container<Key>(keyedBy key: Key.Type) throws ->
    KeyedDecodingContainer<Key> where Key: CodingKey {
        
        switch self.json {
        case .object(let dictionary):
            let container = KeyedContainer<Key>(
                impl: self,
                codingPath: codingPath,
                dictionary: dictionary
            )
            return KeyedDecodingContainer(container)
        case .string(let string): // json string modeling compatibility
            if let dict = string.toJSONObject() as? [String: Any],
               let dictionary = JSONValue.make(dict)?.object {
                let container = KeyedContainer<Key>(
                    impl: self,
                    codingPath: codingPath,
                    dictionary: dictionary
                )
                return KeyedDecodingContainer(container)
            }
        case .null:
            throw DecodingError.valueNotFound([String: JSONValue].self, DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Cannot get keyed decoding container -- found null value instead"
            ))
        default:
            break
        }
        throw DecodingError._typeMismatch(at: codingPath, expectation: [String: JSONValue].self, desc: json.debugDataTypeDescription)
    }
    
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        switch self.json {
        case .array(let array):
            return UnkeyedContainer(
                impl: self,
                codingPath: self.codingPath,
                array: array
            )
        case .string(let string): // json字符串的模型化兼容
            if let arr = string.toJSONObject() as? [Any],
               let array = JSONValue.make(arr)?.array {
                return UnkeyedContainer(
                    impl: self,
                    codingPath: self.codingPath,
                    array: array
                )
            }
        case .null:
            throw DecodingError.valueNotFound([String: JSONValue].self, DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Cannot get unkeyed decoding container -- found null value instead"
            ))
        default:
            break
        }
        throw DecodingError.typeMismatch([JSONValue].self, DecodingError.Context(
            codingPath: self.codingPath,
            debugDescription: "Expected to decode \([JSONValue].self) but found \(self.json.debugDataTypeDescription) instead."
        ))
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(
            impl: self,
            codingPath: self.codingPath,
            json: self.json
        )
    }
}




internal struct _JSONKey: CodingKey {
    public var stringValue: String
    public var intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }
    
    internal init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }
    
    internal static let `super` = _JSONKey(stringValue: "super")!
}

