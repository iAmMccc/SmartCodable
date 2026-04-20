# Phase 3: 代码重构评估

**提交:** 见 git log  
**分支:** `6.1.0`  
**日期:** 2026-04-20

---

## 评估方法

对工作计划中列出的 8 个重构点，逐一读取相关代码，基于事实逻辑判断是否值得修改。

---

## 实际修复

### 1. SmartDate.swift 重复 `import Foundation`

**文件:** `Sources/SmartCodable/Core/PropertyWrapper/SmartDate.swift`

**问题:** 第 8-9 行重复了 `import Foundation`。

**修复:** 删除重复的一行。零风险。

---

## 评估后决定不修复的问题

### 1. `didFinishMapping` 在 KeyedContainer 和 UnkeyedContainer 中"重复"

**结论：不改。**

两个实现**不是简单重复**：

- **KeyedContainer 版本**：直接尝试 `as? SmartDecodable` 转换
- **UnkeyedContainer 版本**：多了一行 `guard T.self is SmartDecodable.Type else { return decodeValue }`，这是一个性能优化——`is` 检查比 `as?` 动态转换更高效，避免了对非 SmartDecodable 类型的不必要开销

强行合并会丢失这个差异，或者引入不必要的抽象。

### 2. SmartAny 整数类型推断的 10 种类型顺序尝试

**结论：不改。**

虽然形式上重复（10 个 `if let ... decodeIfPresent` 分支），但改成循环需要类型擦除 `[Any.Type]`，会：
- 降低代码可读性和 debug 能力
- 引入 `Any.Type` 的动态分发开销
- 收益有限（只减少约 15 行代码）

同时确认：此处的逻辑与 `JSONDecoderImpl+Unwrap.swift` 中的 `unwrapFixedWidthInteger` **语义不同**。前者是"类型推断"（找到第一个能成功解码的类型），后者是"类型验证"（验证精度是否匹配）。不能合并。

### 3. SmartCompact.Array / Dictionary 未遵循 PropertyWrapperable

**结论：不改。这是设计决策，不是遗漏。**

SmartCompact 类型有自己完整的 `Codable` 实现，用于容错解析（跳过无效元素）。它们不需要 PropertyWrapperable 的回调机制（`wrappedValueDidFinishMapping`、`createInstance` 等），因为：
- 它们不直接包装 SmartDecodable 对象
- 它们有独立的 `init(from decoder:)` 实现
- 它们的使用模式与其他属性包装器不同

### 4. `preconditionFailure` / `fatalError` 替换为 throw

**结论：不改。**

经逐一审查 10 处调用：

- **JSONEncoderImpl.swift（3 处）：** `container(keyedBy:)`、`unkeyedContainer()`、`singleValueContainer()` 是 `Encoder` 协议的实现，协议签名是**非 throws 的**，无法改为 throw。Apple 的 JSONEncoder 也使用同样的 `preconditionFailure`。
- **JSONFuture.swift（7 处）：** 均为 `@inline(__always)` 的内部方法，检测的是 Encoder 协议的内部契约违反。改为 throw 需要改变整条调用链的函数签名，而调用链顶层受 Encoder 协议约束无法 throws。Apple 的实现也是 `preconditionFailure`。
- **fatalError（2 处）：** 在 `#available` 守卫之后，仅当 iOS < 10.0 等不支持的平台才会到达。SmartCodable 最低支持 iOS 13+，永远不会触发。

### 5. 日志代码无条件编译保护

**结论：不改。**

如果使用 `#if DEBUG` 包裹日志代码，Release 构建中将完全无法使用 SmartSentinel。而实际场景中，开发者可能需要在 TestFlight 或线上环境临时开启日志排查数据解析问题。当前实现（`debugMode` 默认 `.none`，运行时守卫）是合理的设计。

### 6. LogCache 无容量上限

**结论：不改。**

`debugMode` 默认 `.none`，只在开发者主动开启时才积累日志。每次解析完成后 `clearCache(parsingMark:)` 会清理本次会话的日志。加容量上限会增加代码复杂度，而实际场景中不会在生产环境长期开启 debugMode。

### 7. Encoder/Decoder snake_case 转换逻辑重复

**结论：不改。**

确认后发现这**不是重复**：
- Encoding：`_convertToSnakeCase()` — camelCase → snake_case
- Decoding：`_convertFromSnakeCase()` — snake_case → camelCase

两者是**反向转换**，算法完全不同。仅 `_convertFirstLetterToLowercase/Uppercase` 两个小函数相同（各 ~10 行），不值得为此引入共享模块。

---

## 修改文件清单

| 文件 | 改动 |
|------|------|
| `SmartDate.swift` | 删除重复的 `import Foundation` |
