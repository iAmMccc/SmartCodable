//
//  SmartSentinel.swift
//  BTCodable
//
//  Created by Mccc on 2023/8/7.
//

import Foundation


/// Central logging configuration and utilities
public struct SmartSentinel {
    
    /// Set debugging mode, default is none.
    /// Note: When not debugging, set to none to reduce overhead.
    public static var debugMode: Level {
        get { return _mode }
        set { _mode = newValue }
    }
    
    /// 设置回调方法，传递解析完成时的日志记录
    public static func onLogGenerated(handler: @escaping (String) -> Void) {
        handlerQueue.sync {
            self.logsHandler = handler
        }
    }
    
    /// Set up different levels of padding
    public static let space: String = "   "
    /// Set the markup for the model
    public static let keyContainerSign: String = "╆━ "
    
    public static let unKeyContainerSign: String = "╆━ "
    
    /// Sets the tag for the property
    public static let attributeSign: String = "┆┄ "
    
    
    /// 是否满足日志记录的条件
    fileprivate static var isValid: Bool {
        return debugMode != .none
    }
    
    private static var _mode = Level.none
    
    private static var cache = LogCache()
    
    /// 回调闭包，用于在解析完成时传递日志
    private static var logsHandler: ((String) -> Void)?
    
    /// 用于同步访问 logsHandler 的队列
    private static let handlerQueue = DispatchQueue(label: "com.smartcodable.handler", qos: .utility)

}


extension SmartSentinel {
    static func monitorLog<T>(impl: JSONDecoderImpl, isOptionalLog: Bool = false,
                              forKey key: CodingKey?, value: JSONValue?, type: T.Type) {
        
        guard SmartSentinel.debugMode != .none else { return }
        guard let key = key else { return }
        // 如果被忽略了，就不要输出log了。
        let typeString = String(describing: T.self)
        guard !typeString.starts(with: "IgnoredKey<") else { return }
        
        let className = impl.cache.findSnapShot(with: impl.codingPath)?.objectTypeName ?? ""
        var path = impl.codingPath
        path.append(key)
        
        var address = ""
        if let parsingMark = CodingUserInfoKey.parsingMark {
            address = impl.userInfo[parsingMark] as? String ?? ""
        }
        
        if let entry = value {
            if entry.isNull { // 值为null
                if isOptionalLog { return }
                let error = DecodingError._valueNotFound(key: key, expectation: T.self, codingPath: path)
                SmartSentinel.verboseLog(error, className: className, parsingMark: address)
            } else { // value类型不匹配
                let error = DecodingError._typeMismatch(at: path, expectation: T.self, desc: entry.debugDataTypeDescription)
                SmartSentinel.alertLog(error: error, className: className, parsingMark: address)
            }
        } else { // key不存在或value为nil
            if isOptionalLog { return }
            let error = DecodingError._keyNotFound(key: key, codingPath: path)
            SmartSentinel.verboseLog(error, className: className, parsingMark: address)
        }
    }
    
    private static func verboseLog(_ error: DecodingError, className: String, parsingMark: String) {
        logIfNeeded(level: .verbose) {
            cache.save(error: error, className: className, parsingMark: parsingMark)
        }
    }
    
    private static func alertLog(error: DecodingError, className: String, parsingMark: String) {
        logIfNeeded(level: .alert) {
            cache.save(error: error, className: className, parsingMark: parsingMark)
        }
    }
    
    static func monitorLogs(in name: String, parsingMark: String, impl: JSONDecoderImpl) {
        
        guard SmartSentinel.isValid else { return }
        
        var header: String?
        if let key = CodingUserInfoKey.logContextHeader {
            header = impl.userInfo[key] as? String
        }
        
        var footer: String?
        if let key = CodingUserInfoKey.logContextFooter {
            footer = impl.userInfo[key] as? String
        }

        
        if let format = cache.formatLogs(parsingMark: parsingMark) {
            var message: String = ""
            message += getHeader(context: header)
            message += name + " 👈🏻 👀\n"
            message += format
            message += getFooter(context: footer)
            print(message)
            
            handlerQueue.sync {
                if let handler = logsHandler {
                    DispatchQueue.main.async {
                        handler(message)
                    }
                }
            }
        }
        
        cache.clearCache(parsingMark: parsingMark)
    }
}



extension SmartSentinel {
    static func monitorAndPrint(level: SmartSentinel.Level = .alert, debugDescription: String, error: Error? = nil, in type: Any.Type?) {
        logIfNeeded(level: level) {
            let decodingError = (error as? DecodingError) ?? DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: debugDescription, underlyingError: error))
            if let logItem = LogItem.make(with: decodingError) {
                
                var message: String = ""
                message += getHeader()
                if let type = type {
                    message += "\(type) 👈🏻 👀\n"
                }
                message += logItem.formartMessage + "\n"
                message += getFooter()
                print(message)
                
                handlerQueue.sync {
                    if let handler = logsHandler {
                        DispatchQueue.main.async {
                            handler(message)
                        }
                    }
                }
            }
        }
    }
}


extension SmartSentinel {
    /// 生成唯一标记，用来标记是否本次解析。
    static func parsingMark() -> String {
        let mark = "SmartMark" + UUID().uuidString
        return mark
    }
}


extension SmartSentinel {
    
    public enum Level: Int, Sendable {
        /// 不记录日志
        case none
        /// 详细的日志
        case verbose
        /// 警告日志：仅仅包含类型不匹配的情况
        case alert
    }
    
    
    static func getHeader(context: String? = nil) -> String {
        let line = "\n================================  [Smart Sentinel]  ================================\n"
        
        if let c = context, !c.isEmpty {
            return line + c + "\n\n"
            
        } else {
            return line
        }
    }
    
    static func getFooter(context: String? = nil) -> String {
        let line = "====================================================================================\n"
        
        if let c = context, !c.isEmpty {
            return "\n" + c + "\n" + line
        } else {
            return line
        }
    }
    
    private static func logIfNeeded(level: SmartSentinel.Level, callback: () -> ()) {
        if SmartSentinel.debugMode.rawValue <= level.rawValue {
            callback()
        }
    }
}
