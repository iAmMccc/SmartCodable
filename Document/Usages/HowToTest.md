# SmartCodable 测试指南

## 运行现有测试

```bash
# 编译项目
swift build

# 运行测试（注意：当前测试文件存在模块名冲突问题，swift test 可能编译失败）
swift test
```

> ⚠️ 已知问题：`Tests/Example.swift` 中 `SmartCodable` 作为类型名与模块名冲突，导致 `swift test` 编译失败。`swift build` 可以正常通过。这是一个待修复的问题。

## 测试文件位置

```
Tests/
├── Example.swift                              # 集成测试
└── SmartSubclassMacroAccessControlTests.swift  # 宏访问控制测试
```

## 手动验证场景

修改核心解码逻辑后，建议至少验证以下场景：

### 基础场景

| 场景 | 验证点 |
|:-----|:------|
| 简单模型解码 | struct / class 基本类型属性正常解析 |
| 嵌套模型 | 嵌套的 SmartCodable 模型正确解析 |
| 数组模型 | `[Model].deserialize(from:)` 正常工作 |
| 可选字段 | `nil`、缺失、正常值三种情况 |

### 容错场景

| 场景 | 验证点 |
|:-----|:------|
| 字段缺失 | 非可选属性使用初始值，可选属性为 nil |
| 类型不匹配 | String ↔ Int、String ↔ Bool 自动转换 |
| null 值 | 非可选属性回退默认值，可选属性为 nil |
| 多余字段 | 不影响解析 |

### 功能场景

| 场景 | 验证点 |
|:-----|:------|
| Key Mapping | `mappingForKey()` 单映射、多候选、嵌套路径 |
| Value Transformer | `mappingForValue()` 自定义转换 |
| @SmartAny | `Any`、`[Any]`、`[String: Any]` |
| @SmartIgnored | 属性值不被 JSON 覆盖 |
| @SmartFlat | 嵌套对象扁平化到父级 |
| @SmartCompact | 数组/字典容错解析 |
| 枚举解码 | SmartCaseDefaultable、SmartAssociatedEnumerable |
| 继承 | @SmartSubclass 子类属性正确解码 |
| didFinishMapping | 回调在解码后执行 |
| SmartUpdater | 增量更新已有模型 |

### 编码场景

| 场景 | 验证点 |
|:-----|:------|
| toDictionary | 基本编码正确 |
| toJSONString | JSON 字符串输出正确 |
| useMappedKeys | 使用映射后的 key 编码 |

## 编写新测试

测试文件放在 `Tests/` 目录下，遵循 XCTest 框架：

```swift
import XCTest
@testable import SmartCodable

final class MyTests: XCTestCase {
    
    func testMissingKeyFallback() {
        struct Model: SmartCodableX {
            var name: String = "default"
            var age: Int = 0
        }
        
        let dict: [String: Any] = ["age": 25]
        let model = Model.deserialize(from: dict)
        
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.name, "default")  // 缺失字段使用初始值
        XCTAssertEqual(model?.age, 25)
    }
    
    func testTypeMismatchAutoConvert() {
        struct Model: SmartCodableX {
            var age: Int = 0
        }
        
        let dict: [String: Any] = ["age": "123"]
        let model = Model.deserialize(from: dict)
        
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.age, 123)  // String → Int 自动转换
    }
}
```

## 质量保障流程

1. **开发自测**：修改代码后，手动验证上述场景
2. **CI 构建**：GitHub Actions 自动执行 `swift build` 和 `swift test`
3. **社区验证**：版本发布前在 QQ 交流群（群号：865036731）进行线上验证
4. **Beta 测试**：大版本更新发布 beta 版公测，周期 2-4 周
