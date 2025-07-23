// 
//  SmartJSONDecoder.swift
//  SmartCodable
//
//  Created by Mccc on 2024/3/4.
//

import Foundation

open class SmartJSONDecoder: JSONDecoder, @unchecked Sendable {
    
    open var smartDataDecodingStrategy: SmartDataDecodingStrategy = .base64
    
    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    struct _Options {
        let dateDecodingStrategy: DateDecodingStrategy?
        let dataDecodingStrategy: SmartDataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
        let keyDecodingStrategy: SmartKeyDecodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
    }
    
    /// The options set on the top-level decoder.
    var options: _Options {
        return _Options(
            dateDecodingStrategy: smartDateDecodingStrategy,
            dataDecodingStrategy: smartDataDecodingStrategy,
            nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy,
            keyDecodingStrategy: smartKeyDecodingStrategy,
            userInfo: userInfo
        )
    }
    
    open var smartDateDecodingStrategy: DateDecodingStrategy?
    
    open var smartKeyDecodingStrategy: SmartKeyDecodingStrategy = .useDefaultKeys

    
    // MARK: - Decoding Values

    /// Decodes a top-level value of the given type from the given JSON representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    /// - throws: An error if any value throws an error during decoding.
    open override func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T {
                
        let mark = SmartSentinel.parsingMark()
        if let parsingMark = CodingUserInfoKey.parsingMark {
            userInfo.updateValue(mark, forKey: parsingMark)
        }
        

        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
            guard let json = JSONValue.make(object) else {
                let error = DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "不支持的 JSON 值类型")
                )
                SmartSentinel.monitorAndPrint(debugDescription: "The given data was not valid JSON.", error: error, in: type)
                throw error
            }

            let impl = JSONDecoderImpl(userInfo: userInfo, from: json, codingPath: [], options: options)
            let value = try impl.unwrap(as: type)

            SmartSentinel.monitorLogs(in: "\(type)", parsingMark: mark, impl: impl)
            return value
        } catch {
            SmartSentinel.monitorAndPrint(debugDescription: "The given data was not valid JSON.", error: error, in: type)
            throw error
        }
    }
}


extension CodingUserInfoKey {
    /// This parsing tag is used to summarize logs.

    static var parsingMark = CodingUserInfoKey.init(rawValue: "Stamrt.parsingMark")
    
    static var logContextHeader = CodingUserInfoKey.init(rawValue: "Stamrt.logContext.header")
    static var logContextFooter = CodingUserInfoKey.init(rawValue: "Stamrt.logContext.footer")
}

