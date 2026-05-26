# 代码质量优化记录

**分支:** `6.1.0`  
**日期:** 2026-04-20

---

## 一、Bug 修复与拼写修正

### 1.1 `decodeIfPresent(String)` 中 `currentIndex` 被递增两次

**文件:** `JSONDecoderImpl+UnkeyedContainer.swift`

**问题:** `currentIndex` 在方法开头被递增了一次，在成功路径末尾又递增了一次。而 fallback 路径 `optionalDecode()` 内部每条分支也会递增 `currentIndex`，导致实际跳过两个元素。

**修复前:**
```swift
mutating func decodeIfPresent(_ type: String.Type) throws -> String? {
    self.currentIndex += 1  // <- 第 1 次递增
    guard let value = try? self.getNextValue(ofType: String.self) else {
        return optionalDecode()  // <- optionalDecode 内部第 2 次递增
    }
    guard case .string(let string) = value else {
        return optionalDecode()  // <- optionalDecode 内部第 2 次递增
    }
    self.currentIndex += 1  // <- 第 2 次递增
    return string
}
```

**修复后:**
```swift
mutating func decodeIfPresent(_ type: String.Type) throws -> String? {
    guard let value = try? self.getNextValue(ofType: String.self) else {
        return optionalDecode()
    }
    guard case .string(let string) = value else {
        return optionalDecode()
    }
    self.currentIndex += 1
    return string
}
```

**验证方式:** 与 `decodeIfPresent(Bool)` 等同类方法结构完全一致；`optionalDecode()` 内部三条路径都会自行递增 `currentIndex`。

### 1.2 `decode(String)` 中 `getNextValue` 误传 `Bool.self`

**文件:** `JSONDecoderImpl+UnkeyedContainer.swift`

**问题:** `decode(_ type: String.Type)` 方法中调用 `getNextValue(ofType: Bool.self)`，应为 `String.self`。

`getNextValue(ofType:)` 的泛型参数 `T` 仅用于错误信息（`valueNotFound` 的类型参数），不影响返回值（始终返回 `self.array[self.currentIndex]`）。因此功能不受影响，但如果数组越界，错误信息会误报为 "Expected Bool" 而非 "Expected String"。

**修复:** `Bool.self` → `String.self`

### 1.3 变量名拼写错误

**涉及文件:**
- `JSONDecoderImpl+Unwrap.swift`: `tranformer` → `transformer`（4 处）
- `JSONDecoderImpl+SingleValueContainer.swift`: `trnas` → `trans`（2 处）

均为局部变量名修正，不影响任何逻辑。

### 1.4 CodingUserInfoKey rawValue 拼写错误

**涉及文件:**
- `SmartJSONEncoder.swift`: `"Stamrt.useMappedKeys"` → `"Smart.useMappedKeys"`
- `SmartJSONDecoder.swift`: `"Stamrt.parsingMark"` → `"Smart.parsingMark"`
- `SmartJSONDecoder.swift`: `"Stamrt.logContext.header"` → `"Smart.logContext.header"`
- `SmartJSONDecoder.swift`: `"Stamrt.logContext.footer"` → `"Smart.logContext.footer"`

**安全性确认:** 这些 rawValue 仅在运行时通过 `CodingUserInfoKey` 静态属性在 encoder/decoder 内部传递，所有访问点均通过静态属性而非硬编码字符串。不存在外部持久化依赖。

---

## 二、线程安全修复

### 2.1 `SmartCodableOptions` 全局配置加锁

**文件:** `SmartCodableOptions.swift`

**问题:** `numberStrategy` 和 `ignoreNull` 是 `public static var`，无任何同步保护。如果一个线程在修改配置的同时，另一个线程正在解码并读取配置，会产生数据竞争。

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
    // ignoreNull 同理
}
```

**API 兼容性:** 公共 API 完全不变。

### 2.2 `SmartSentinel.debugMode` 加锁

**文件:** `SmartSentinel.swift`

**问题:** `_mode` 是 `private static var`，`debugMode` 的 getter/setter 直接读写它，无同步保护。Swift 语言规范不保证 enum 赋值的原子性，存在 data race。

**修复方案:** 引入 `modeLock`（NSLock），保护 `_mode` 的读写。

**API 兼容性:** 公共 API 完全不变。

### 2.3 评估后决定不修复的问题

| 问题 | 结论 | 理由 |
|------|------|------|
| `@unchecked Sendable` 标记 | 不改 | Apple 的 `JSONEncoder`/`JSONDecoder` 自身也标记了 `@unchecked Sendable`，SmartCodable 跟随父类行为合理 |
| `_iso8601Formatter` 全局共享 | 不改 | Apple 的 Foundation `JSONDecoder` 源码中采用了相同写法 |
| `SmartSentinel.cache`（LogCache struct） | 不改 | 其唯一存储属性 `snapshotDict` 是 `SafeDictionary`（class 类型，自带 NSLock），struct copy 时拷贝的是同一个 class 引用，线程安全由 `SafeDictionary` 保证 |

---

## 三、代码重构评估

对工作计划中列出的 8 个重构点，逐一读取相关代码，基于事实逻辑判断是否值得修改。

### 3.1 实际修复

**SmartDate.swift 重复 `import Foundation`** — 删除重复的一行。

### 3.2 评估后决定不修复的问题

| 问题 | 结论 | 理由 |
|------|------|------|
| `didFinishMapping` 重复 | 不改 | 两个实现**不同**：UnkeyedContainer 版本多了 `guard T.self is SmartDecodable.Type` 性能优化 |
| SmartAny 整数推断 10 种类型 | 不改 | 改循环需类型擦除 `[Any.Type]`，降低可读性和 debug 能力，收益有限 |
| SmartCompact 未遵循 PropertyWrapperable | 不改 | 设计决策，SmartCompact 有独立的 Codable 实现，不需要该协议的回调机制 |
| `preconditionFailure` / `fatalError` | 不改 | 受 `Encoder` 协议签名约束（非 throws），无法改为 throw；Apple 的 JSONEncoder 也使用同样的 `preconditionFailure` |
| 日志代码无条件编译保护 | 不改 | 开发者可能需要在 Release 环境临时开启日志排查问题，`#if DEBUG` 会阻止这一场景 |
| LogCache 无容量上限 | 不改 | `debugMode` 默认 `.none`，每次解析后自动清理，实际不会长期积累 |
| Encoder/Decoder snake_case 重复 | 不改 | 确认是**反向转换**（camelCase→snake_case vs snake_case→camelCase），算法不同 |

---

## 修改文件汇总

| 文件 | 改动 |
|------|------|
| `JSONDecoderImpl+UnkeyedContainer.swift` | 修复 currentIndex 双重递增；修复 Bool.self 误传 |
| `JSONDecoderImpl+Unwrap.swift` | 修正 `tranformer` → `transformer`（4 处） |
| `JSONDecoderImpl+SingleValueContainer.swift` | 修正 `trnas` → `trans`（2 处） |
| `SmartJSONDecoder.swift` | 修正 `Stamrt` → `Smart`（3 处） |
| `SmartJSONEncoder.swift` | 修正 `Stamrt` → `Smart`（1 处） |
| `SmartCodableOptions.swift` | 添加 NSLock 保护 `numberStrategy` 和 `ignoreNull` |
| `SmartSentinel.swift` | 添加 modeLock 保护 `debugMode` |
| `SmartDate.swift` | 删除重复的 `import Foundation` |
