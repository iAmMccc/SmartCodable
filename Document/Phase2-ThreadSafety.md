# Phase 2: 线程安全修复

**提交:** 见 git log  
**分支:** `6.1.0`  
**日期:** 2026-04-20

---

## 修复范围

本轮修复全局可变状态的线程安全问题，确保多线程环境下不会出现数据竞争。

---

## 修复内容

### 1. `SmartCodableOptions` 全局配置加锁

**文件:** `Sources/SmartCodable/Core/SmartCodable/SmartCodableOptions.swift`

**问题:** `numberStrategy` 和 `ignoreNull` 是 `public static var`，无任何同步保护。如果一个线程在修改配置的同时，另一个线程正在解码并读取配置，会产生数据竞争（data race）。

**修复方案:** 引入 `NSLock`，将存储属性改为 private，通过 computed property 加锁访问。

**修复前:**
```swift
public struct SmartCodableOptions {
    public static var numberStrategy: NumberConversionStrategy = .strict
    public static var ignoreNull: Bool = true
}
```

**修复后:**
```swift
public struct SmartCodableOptions {
    private static let lock = NSLock()
    private static var _numberStrategy: NumberConversionStrategy = .strict
    private static var _ignoreNull: Bool = true

    public static var numberStrategy: NumberConversionStrategy {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _numberStrategy
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _numberStrategy = newValue
        }
    }

    public static var ignoreNull: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _ignoreNull
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _ignoreNull = newValue
        }
    }
}
```

**API 兼容性:** 公共 API 完全不变，外部调用方式 `SmartCodableOptions.numberStrategy = .truncate` 无需任何修改。

---

### 2. `SmartSentinel.debugMode` 加锁

**文件:** `Sources/SmartCodable/Core/Sentinel/SmartSentinel.swift`

**问题:** `_mode` 是 `private static var`，`debugMode` 的 getter/setter 直接读写它，无同步保护。虽然 `debugMode` 通常在启动时设置、后续只读，但 Swift 语言规范不保证 enum 赋值的原子性，严格来说仍存在 data race。

**修复方案:** 引入独立的 `modeLock`（NSLock），保护 `_mode` 的读写。

**修复前:**
```swift
public static var debugMode: Level {
    get { return _mode }
    set { _mode = newValue }
}
private static var _mode = Level.none
```

**修复后:**
```swift
private static let modeLock = NSLock()

public static var debugMode: Level {
    get {
        modeLock.lock()
        defer { modeLock.unlock() }
        return _mode
    }
    set {
        modeLock.lock()
        defer { modeLock.unlock() }
        _mode = newValue
    }
}
private static var _mode = Level.none
```

**API 兼容性:** 公共 API 完全不变。

---

## 评估后决定不修复的问题

### `@unchecked Sendable` 标记

`SmartJSONEncoder` 和 `SmartJSONDecoder` 继承自 Apple 的 `JSONEncoder` / `JSONDecoder`，Apple 自身在 Swift 5.5+ 已给父类标记 `@unchecked Sendable`。SmartCodable 跟随父类行为是合理的，且这两个类的典型使用模式是每次解码创建新实例，不跨线程共享。**不改。**

### `_iso8601Formatter` 全局共享

Apple 的 Foundation `JSONDecoder` 源码中也采用了全局共享 `_iso8601Formatter` 的写法。SmartCodable 这部分代码是从 Apple 源码借鉴的，如果 Apple 认为这样做没问题，修改它属于过度修复。**不改。**

### `SmartSentinel.cache`（LogCache struct）

`LogCache` 虽是 struct（作为 `static var`），但其唯一的存储属性 `snapshotDict` 是 `SafeDictionary`（class 类型，自带 NSLock 保护）。当 struct 被 copy 时，拷贝的是同一个 `SafeDictionary` 实例的引用，底层操作仍然由 `SafeDictionary` 的锁保护。**不改。**

---

## 修改文件清单

| 文件 | 改动 |
|------|------|
| `SmartCodableOptions.swift` | 添加 `NSLock`，`numberStrategy` 和 `ignoreNull` 改为锁保护的 computed property |
| `SmartSentinel.swift` | 添加 `modeLock`，`debugMode` 改为锁保护的 computed property |
