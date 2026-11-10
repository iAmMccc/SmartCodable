// 
//  SmartJSONDecoder.swift
//  SmartCodable
//
//  Created by Mccc on 2024/3/4.
//

import Foundation

/// With fixed configuration, smartDecode keeps decoding sessions independent.
/// Do not concurrently mutate strategies/userInfo. Caller-owned reference values
/// and custom decoding implementations remain responsible for their own safety.
open class SmartJSONDecoder: JSONDecoder, @unchecked Sendable {
    
    open var smartDataDecodingStrategy: SmartDataDecodingStrategy = .base64
    
    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    struct _Options {
        let dateDecodingStrategy: DateDecodingStrategy?
        let dataDecodingStrategy: SmartDataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
        let keyDecodingStrategy: SmartKeyDecodingStrategy
        let booleanToIntegerDecodingStrategy: BooleanToIntegerDecodingStrategy
        var userInfo: [CodingUserInfoKey : Any]
        var preMappedRootType: (any SmartDecodable.Type)? = nil
        var unkeyedDecodingStrategy: UnkeyedDecodingStrategy = .legacy
    }
    
    /// The options set on the top-level decoder.
    var options: _Options {
        return _Options(
            dateDecodingStrategy: smartDateDecodingStrategy,
            dataDecodingStrategy: smartDataDecodingStrategy,
            nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy,
            keyDecodingStrategy: smartKeyDecodingStrategy,
            booleanToIntegerDecodingStrategy: smartBooleanToIntegerDecodingStrategy,
            userInfo: userInfo,
            unkeyedDecodingStrategy: smartUnkeyedDecodingStrategy
        )
    }
    
    open var smartDateDecodingStrategy: DateDecodingStrategy?
    
    open var smartKeyDecodingStrategy: SmartKeyDecodingStrategy = .useDefaultKeys

    
    public enum UnkeyedDecodingStrategy: Sendable {
        case legacy
        case consumeOnce
    }

    open var smartUnkeyedDecodingStrategy: UnkeyedDecodingStrategy = .legacy

    /// Controls how a JSON boolean is accepted when decoding a fixed-width integer.
    /// `.legacy` preserves the existing accepted domain. `.zeroOrOne` additionally
    /// accepts `true` as 1 and `false` as 0 through the integer Patcher.
    public enum BooleanToIntegerDecodingStrategy: Sendable {
        case legacy
        case zeroOrOne
    }

    open var smartBooleanToIntegerDecodingStrategy: BooleanToIntegerDecodingStrategy = .legacy

    // MARK: - Decoding Values

    /// Decodes a top-level value of the given type from the given JSON representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    /// - throws: An error if any value throws an error during decoding.
    public func smartDecode<T : Decodable>(_ type: T.Type, from input: Any) throws -> T {
                
        return try decodeValue(type, from: input)
    }

    /// Updater resolves only the root model's field names before merging.
    func decodeValue<T: Decodable>(_ type: T.Type, from input: Any,
                                   preMappedRootType: (any SmartDecodable.Type)? = nil) throws -> T {
        let mark = SmartSentinel.parsingMark()
        var callOptions = options
        callOptions.preMappedRootType = preMappedRootType
        if let parsingMark = CodingUserInfoKey.parsingMark {
            callOptions.userInfo[parsingMark] = mark
        }
        
        
        // 将数据转成object
        let jsonObject: Any
        switch input {
        case let data as Data:
            do {
                jsonObject = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
            } catch {
                SmartSentinel.monitorAndPrint(debugDescription: "The given data was not valid JSON.", error: error, in: type)
                throw error
            }
            
        case let dict as [String: Any]:
            jsonObject = dict
            
        case let arr as [Any]:
            jsonObject = arr
            
        case let json as String:
            guard let object = json.toJSONObject() else {
                let error = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "不支持的 JSON 值类型"))
                SmartSentinel.monitorAndPrint(debugDescription: "The given data was not valid JSON.", error: error, in: type)
                throw error
            }
            jsonObject = object
        default:
            let error = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "不支持的 JSON 值类型"))
            SmartSentinel.monitorAndPrint(debugDescription: "The given data was not valid JSON.", error: error, in: type)
            throw error
        }

        // 将object转成解析内部需要的 `JSONValue`
        guard let json = JSONValue.make(jsonObject) else {
            let error = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "不支持的 JSON 值类型"))
            SmartSentinel.monitorAndPrint(debugDescription: "The given data was not valid JSON.", error: error, in: type)
            throw error
        }

        // 执行解析逻辑
        let impl = JSONDecoderImpl(userInfo: callOptions.userInfo, from: json, codingPath: [], options: callOptions)
        do {
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

    static var parsingMark = CodingUserInfoKey.init(rawValue: "Smart.parsingMark")
    
    static var logContextHeader = CodingUserInfoKey.init(rawValue: "Smart.logContext.header")
    static var logContextFooter = CodingUserInfoKey.init(rawValue: "Smart.logContext.footer")
}

