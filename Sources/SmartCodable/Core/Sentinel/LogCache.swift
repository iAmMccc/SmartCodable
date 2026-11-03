//
//  LogCache.swift
//  SmartCodable
//
//  Created by Mccc on 2024/4/23.
//

import Foundation

/**
 A logging system for tracking and reporting decoding errors in SmartCodable parsing.
 
 The system provides:
 - Hierarchical error logging with visual formatting
 - Configurable logging levels
 - Thread-safe logging operations
 - Customizable output handlers
 */
/// Thread-safe cache for decoding diagnostics.
///
/// `LogCache` is shared by every decoder invocation. All mutable state is
/// therefore guarded by one lock; `SafeDictionary`'s internal locks only
/// protect its own storage and cannot make a whole `LogCache` mutation atomic.
final class LogCache {

    private let lock = NSLock()
    private var snapshotDict = SafeDictionary<String, LogContainer>()

    /// Saves a decoding error to the log cache
    func save(error: DecodingError, className: String, parsingMark: String) {
        lock.lock()
        defer { lock.unlock() }
        let log = LogItem.make(with: error)
        cacheLog(log, className: className, parsingMark: parsingMark)
    }

    /// Clears cached logs for a specific parsing session
    func clearCache(parsingMark: String) {
        lock.lock()
        defer { lock.unlock() }
        snapshotDict.removeValue { $0.hasPrefix(parsingMark) }
    }

    /// Formats all logs for a parsing session into a readable string
    func formatLogs(parsingMark: String) -> String? {
        lock.lock()
        defer { lock.unlock() }

        filterLogItem(parsingMark: parsingMark)

        alignTypeNamesInAllSnapshots(parsingMark: parsingMark)

        let keyOrder = sortKeys(snapshotDict.getAllKeys(), parsingMark: parsingMark)

        var lastPath: String = ""
        let arr = keyOrder.compactMap {
            let container = snapshotDict.getValue(forKey: $0)
            let message = container?.formatMessage(previousPath: lastPath)
            lastPath = container?.path ?? ""
            return message
        }

        if arr.isEmpty { return nil }
        return arr.joined()
    }
}

extension LogCache {
    
    /// Sorts log keys for consistent output ordering
    func sortKeys(_ array: [String], parsingMark: String) -> [String] {
        //  获取当前解析的keys
        let filterArray = array.filter {
            $0.starts(with: parsingMark)
        }
        guard !filterArray.isEmpty else { return [] }
        
        let sortedArray = filterArray.sorted()
        return sortedArray
    }
    
    /// Filters duplicate log items across containers
    func filterLogItem(parsingMark: String) {
        let pattern = "Index \\d+"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        var matchedKeys = snapshotDict.getAllKeys().filter { key in
            guard key.hasPrefix(parsingMark) else { return false }
            let range = NSRange(key.startIndex..<key.endIndex, in: key)
            return regex.firstMatch(in: key, options: [], range: range) != nil
        }
        
        matchedKeys = matchedKeys.sorted(by: < )
        
        var allLogs: [LogItem] = []
        
        let tempDict = snapshotDict
        for key in matchedKeys {
            var lessLogs: [LogItem] = []
            if var snap = snapshotDict.getValue(forKey: key) {
                let logs = snap.logs
                for log in logs {
                    if !allLogs.contains(where: { $0 == log }) {
                        lessLogs.append(log)
                        allLogs.append(log)
                    }
                }
                
                if lessLogs.isEmpty {
                    tempDict.removeValue(forKey: key)
                } else {
                    snap.logs = lessLogs
                    tempDict.setValue(snap, forKey: key)
                }
            }
        }
        snapshotDict = tempDict
    }
    
    /// Caches an individual log item
    private func cacheLog(_ log: LogItem?, className: String, parsingMark: String) {
        
        guard let log = log else { return }
        
        let path = log.codingPath
        let key = createKey(path: path, parsingMark: parsingMark)
        
        // 如果存在相同的typeName和path，则合并logs
        if var existingSnapshot = snapshotDict.getValue(forKey: key) {
            if !existingSnapshot.logs.contains(where: { $0 == log }) {
                existingSnapshot.logs.append(log)
                snapshotDict.setValue(existingSnapshot, forKey: key)
            }
        } else {
            // 创建新的snapshot并添加到字典中
            let newSnapshot = LogContainer(typeName: className, codingPath: path, logs: [log], parsingMark: parsingMark)
            snapshotDict.setValue(newSnapshot, forKey: key)
        }
    }
    
    /// Creates a unique key for a log entry.
    ///
    /// Each path component is length-prefixed instead of joined with a plain
    /// separator: `"user-name"` must not collide with the nested path
    /// `["user", "name"]`.
    private func createKey(path: [CodingKey], parsingMark: String) -> String {
        var key = parsingMark
        for component in path {
            let value = component.stringValue
            key += "\(value.count):\(value)"
        }
        return key
    }

    /// Aligns field names for consistent visual output
    private func alignTypeNamesInAllSnapshots(parsingMark: String) {
        snapshotDict.updateEach { key, snapshot in
            guard key.hasPrefix(parsingMark) else { return }
            let maxLength = snapshot.logs.max(by: { $0.fieldName.count < $1.fieldName.count })?.fieldName.count ?? 0
            snapshot.logs = snapshot.logs.map { log in
                var modifiedLog = log
                modifiedLog.fieldName = modifiedLog.fieldName.padding(toLength: maxLength, withPad: " ", startingAt: 0)
                return modifiedLog
            }
        }
    }
}




