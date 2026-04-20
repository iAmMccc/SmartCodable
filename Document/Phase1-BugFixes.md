# Phase 1: Bug 修复与拼写修正

**提交:** `ea73997`  
**分支:** `6.1.0`  
**日期:** 2026-04-20

---

## 修复内容

### Bug 1: `decodeIfPresent(String)` 中 `currentIndex` 被递增两次

**文件:** `Sources/SmartCodable/Core/JSONDecoder/Decoder/Impl/JSONDecoderImpl+UnkeyedContainer.swift`

**问题:** 在 `UnkeyedContainer` 的 `decodeIfPresent(_ type: String.Type)` 方法中，`currentIndex` 在方法开头被递增了一次，在成功路径末尾又递增了一次。而 fallback 路径 `optionalDecode()` 内部每条分支也会递增 `currentIndex`，导致实际跳过两个元素。

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

---

### Bug 2: `decode(String)` 中 `getNextValue` 误传 `Bool.self`

**文件:** `Sources/SmartCodable/Core/JSONDecoder/Decoder/Impl/JSONDecoderImpl+UnkeyedContainer.swift`

**问题:** `decode(_ type: String.Type)` 方法中调用 `getNextValue(ofType: Bool.self)`，应为 `String.self`。

`getNextValue(ofType:)` 的泛型参数 `T` 仅用于错误信息（`valueNotFound` 的类型参数），不影响返回值（始终返回 `self.array[self.currentIndex]`）。因此功能不受影响，但如果数组越界，错误信息会误报为 "Expected Bool" 而非 "Expected String"。

**修复:** `Bool.self` -> `String.self`

---

### Bug 3: 变量名拼写错误

**涉及文件:**
- `JSONDecoderImpl+Unwrap.swift`: `tranformer` -> `transformer`（4 处）
- `JSONDecoderImpl+SingleValueContainer.swift`: `trnas` -> `trans`（2 处）

均为局部变量名修正，不影响任何逻辑。

---

### Bug 4: CodingUserInfoKey rawValue 拼写错误

**涉及文件:**
- `SmartJSONEncoder.swift`: `"Stamrt.useMappedKeys"` -> `"Smart.useMappedKeys"`
- `SmartJSONDecoder.swift`: `"Stamrt.parsingMark"` -> `"Smart.parsingMark"`
- `SmartJSONDecoder.swift`: `"Stamrt.logContext.header"` -> `"Smart.logContext.header"`
- `SmartJSONDecoder.swift`: `"Stamrt.logContext.footer"` -> `"Smart.logContext.footer"`

**安全性确认:** 这些 rawValue 仅在运行时通过 `CodingUserInfoKey` 静态属性在 encoder/decoder 内部传递，所有访问点均通过静态属性（如 `CodingUserInfoKey.parsingMark`）而非硬编码字符串。不存在外部持久化依赖。

---

## 修改文件清单

| 文件 | 改动 |
|------|------|
| `JSONDecoderImpl+UnkeyedContainer.swift` | 修复 currentIndex 双重递增；修复 Bool.self 误传 |
| `JSONDecoderImpl+Unwrap.swift` | 修正 `tranformer` -> `transformer`（4 处） |
| `JSONDecoderImpl+SingleValueContainer.swift` | 修正 `trnas` -> `trans`（2 处） |
| `SmartJSONDecoder.swift` | 修正 `Stamrt` -> `Smart`（3 处） |
| `SmartJSONEncoder.swift` | 修正 `Stamrt` -> `Smart`（1 处） |

**总计:** 5 文件，17 行插入，18 行删除
