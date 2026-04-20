<p align="center">
<img src="https://github.com/intsig171/SmartCodable/assets/87351449/89de27ac-1760-42ee-a680-4811a043c8b1" alt="SmartCodable" title="SmartCodable" width="500"/>
</p>
<h1 align="center">SmartCodable - 强大而灵活的 Swift JSON 解析</h1>

<p align="center">
<a href="https://github.com/iAmMccc/SmartCodable/releases">
    <img src="https://img.shields.io/github/v/release/iAmMccc/SmartCodable?color=blue&label=version" alt="Latest Release">
</a>
<a href="https://swift.org/">
    <img src="https://img.shields.io/badge/Swift-5.0%2B-orange.svg" alt="Swift 5.0+">
</a>
<a href="https://github.com/iAmMccc/SmartCodable/wiki">
    <img src="https://img.shields.io/badge/Documentation-available-brightgreen.svg" alt="Documentation">
</a>
<a href="https://swift.org/package-manager/">
    <img src="https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat" alt="SPM Supported">
</a>
<a href="https://github.com/iAmMccc/SmartCodable/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-black.svg" alt="MIT License">
</a>
<a href="https://deepwiki.com/intsig171/SmartCodable">
    <img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki">
</a>
</p>

[English](README.md) | 中文

**SmartCodable** 基于 Apple 原生 Codable 协议，为其注入了生产环境级别的容错能力。原生 Codable 在遇到一个字段缺失或类型不匹配时，整个模型解析就会失败；而 SmartCodable 能够优雅地恢复——自动回退到默认值、智能转换类型，永不中断解析流程。

## 为什么选择 SmartCodable？

| 场景 | 原生 Codable | SmartCodable |
|:-----|:------------|:-------------|
| 字段缺失 | ❌ 抛出 `keyNotFound`，整个模型解析失败 | ✅ 使用属性初始值作为默认值 |
| 类型不匹配（如 `"123"` 对应 `Int`） | ❌ 抛出 `typeMismatch`，整个模型解析失败 | ✅ 自动转换，返回 `123` |
| 非可选属性收到 null | ❌ 抛出 `valueNotFound`，整个模型解析失败 | ✅ 回退到默认值 |
| 多余的未知字段 | ✅ 自动忽略 | ✅ 自动忽略 |

**对比 HandyJSON**：SmartCodable 基于 Apple 的 Codable 协议构建，不使用不安全的运行时反射，没有 ABI 稳定性风险。HandyJSON 依赖 Swift metadata 反射，可能在 Swift 版本升级时发生兼容性问题。

**对比手写 `init(from:)`**：SmartCodable 消除了为每个属性编写 `decodeIfPresent` + `??` 的样板代码。同样安全，但零负担。



## 快速开始

```swift
import SmartCodable

struct User: SmartCodableX {
    var name: String = ""
    var age: Int = 0
}

// ✅ 正常解析
let user = User.deserialize(from: ["name": "John", "age": 30])
// User(name: "John", age: 30)

// ✅ 字段缺失 — 自动使用默认值
let user2 = User.deserialize(from: ["name": "John"])
// User(name: "John", age: 0)

// ✅ 类型不匹配 — 自动转换
let user3 = User.deserialize(from: ["name": "John", "age": "30"])
// User(name: "John", age: 30)
```

遵循 `SmartCodable` 的 class 需要实现空初始化器：

```swift
class BasicTypes: SmartCodableX {
    var int: Int = 2
    var doubleOptional: Double?
    required init() {}
}
let model = BasicTypes.deserialize(from: json)
```

struct 由编译器提供默认空初始化器，可以直接使用：

```swift
struct BasicTypes: SmartCodableX {
    var int: Int = 2
    var doubleOptional: Double?
}
let model = BasicTypes.deserialize(from: json)
```



## 安装

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/iAmMccc/SmartCodable.git", from: "xxx")
]
```

- `SmartCodable`（核心模块）无需 Swift Macro 支持
- `SmartCodableInherit`（通过 `@SmartSubclass` 实现继承）需要 **Xcode 15+** 和 **Swift 5.9+**

### CocoaPods

| 版本 | 安装方式 | 环境要求 |
|:----|:--------|:--------|
| 基础版 | `pod 'SmartCodable'` | iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+ |
| 继承版 | `pod 'SmartCodable/Inherit'` | iOS 13+, macOS 11+, Xcode 15+, Swift 5.9+ |

> ⚠️ **重要说明**：
> - 如果没有强继承需求，推荐使用基础版
> - 继承功能需要 **Swift Macro 支持**、**Xcode 15+** 和 **Swift 5.9+**

> 📌 **关于 Swift Macros 支持（CocoaPods）**：
> - 首次编译需要下载 `swift-syntax` 依赖（可能耗时较长）
> - CocoaPods 内部会设置 `user_target_xcconfig["OTHER_SWIFT_FLAGS"]` 来加载宏插件
> - 在复杂项目或 CI 环境中可能会影响主 target 的编译标志
> - 如有问题，请 [提交 Issue](https://github.com/iAmMccc/SmartCodable/issues)



## 功能特性

### 1. 反序列化

只有遵循 `SmartCodable`（或 `[SmartCodable]` 数组）的类型才能使用以下方法：

```swift
public static func deserialize(from dict: [String: Any]?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self?

public static func deserialize(from json: String?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self?

public static func deserialize(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self?

public static func deserializePlist(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self?
```

**多格式输入支持：**

| 输入类型 | 使用示例 | 内部转换 |
|:--------|:--------|:--------|
| 字典 | `Model.deserialize(from: dict)` | 直接处理原生集合 |
| 数组 | `[Model].deserialize(from: arr)` | 直接处理原生集合 |
| JSON 字符串 | `Model.deserialize(from: jsonString)` | 通过 UTF-8 转为 Data |
| Data | `Model.deserialize(from: data)` | 直接处理 |

**嵌套路径提取** — 直接定位深层数据：

```swift
// JSON: {"data": {"user": {"info": { ... }}}}
let model = Model.deserialize(from: json, designatedPath: "data.user.info")
```

**解码策略：**

```swift
let options: Set<SmartDecodingOption> = [
    .key(.convertFromSnakeCase),    // snake_case → camelCase
    .date(.iso8601),                // ISO 8601 日期格式
    .data(.base64)                  // Base64 数据解码
]
let model = Model.deserialize(from: json, options: options)
```

| 策略类型 | 可选项 | 说明 |
|:--------|:------|:-----|
| **Key 解码** | `.fromSnakeCase` | snake_case → camelCase |
|              | `.firstLetterLower` | "FirstName" → "firstName" |
|              | `.firstLetterUpper` | "firstName" → "FirstName" |
| **Date 解码** | `.iso8601`、`.secondsSince1970` 等 | 完整的 Codable 日期策略 |
| **Data 解码** | `.base64` | 二进制数据处理 |
| **Float 解码** | `.convertToString`、`.throw` | NaN/∞ 处理 |

> ⚠️ **注意**：每种类型只能设置一个策略（重复时最后一个生效）

### 2. Key 映射

将 JSON 字段名映射到 Swift 属性名，多个候选字段按顺序匹配，首个非 null 的值胜出：

```swift
static func mappingForKey() -> [SmartKeyTransformer]? {
    [
        CodingKeys.id <--- ["user_id", "userId", "id"],
        CodingKeys.name <--- "nested.path.to.name"     // 支持嵌套路径
    ]
}
```

### 3. 值转换

在 JSON 值与自定义类型之间进行转换：

```swift
static func mappingForValue() -> [SmartValueTransformer]? {
    [
        CodingKeys.url <--- SmartURLTransformer(prefix: "https://"),
        CodingKeys.date <--- SmartDateFormatTransformer(DateFormatter()),
        CodingKeys.status <--- FastTransformer<Status, String>(
            fromJSON: { Status(rawValue: $0 ?? "") },
            toJSON: { $0?.rawValue }
        ),
    ]
}
```

**内置转换器：**

| 转换器 | 转换方向 |
|:------|:--------|
| `SmartDateTransformer` | Double/String → Date |
| `SmartDateFormatTransformer` | 自定义格式字符串 → Date |
| `SmartDataTransformer` | Base64 字符串 → Data |
| `SmartURLTransformer` | 字符串 → URL（支持自动添加前缀和 URL 编码） |
| `SmartHexColorTransformer` | 十六进制字符串 → UIColor/NSColor |

需要自定义转换逻辑？实现 `ValueTransformable` 协议即可：

```swift
public protocol ValueTransformable {
    associatedtype Object
    associatedtype JSON
    func transformFromJSON(_ value: Any?) -> Object?
    func transformToJSON(_ value: Object?) -> JSON?
}
```

### 4. 属性包装器

| 包装器 | 用途 | 示例 |
|:------|:-----|:----|
| `@SmartAny` | 支持 `Any`、`[Any]`、`[String: Any]` | `@SmartAny var dict: [String: Any] = [:]` |
| `@SmartIgnored` | 跳过该属性的解码 | `@SmartIgnored var cache: String = ""` |
| `@SmartFlat` | 将嵌套对象扁平化到父模型 | `@SmartFlat var profile: Profile?` |
| `@SmartPublished` | 配合 Combine 的 ObservableObject | `@SmartPublished var name: String?` |
| `@SmartHexColor` | 十六进制字符串 → UIColor/NSColor | `@SmartHexColor var color: UIColor?` |
| `@SmartDate` | 多格式日期自动解析 | `@SmartDate var date: Date?` |
| `@SmartCompact.Array` | 容错数组解析，跳过无效元素 | `@SmartCompact.Array var ids: [Int]` |
| `@SmartCompact.Dictionary` | 容错字典解析，跳过无效键值对 | `@SmartCompact.Dictionary var info: [String: String]` |

**@SmartAny 示例** — 支持 Codable 原生不支持的 `Any` 类型：

```swift
struct Model: SmartCodableX {
    @SmartAny var dict: [String: Any] = [:]
    @SmartAny var arr: [Any] = []
    @SmartAny var any: Any?
}
let dict: [String: Any] = [
    "dict": ["name": "Lisa"],
    "arr": [1, 2, 3],
    "any": "Mccc"
]
let model = Model.deserialize(from: dict)
// Model(dict: ["name": "Lisa"], arr: [1, 2, 3], any: "Mccc")
```

**@SmartIgnored 示例** — 跳过属性解码：

```swift
struct Model: SmartCodableX {
    @SmartIgnored
    var name: String = ""
}
let model = Model.deserialize(from: ["name": "Mccc"])
// Model(name: "")  — "name" 被忽略，保持默认值
```

**@SmartFlat 示例** — 将嵌套字段扁平化到父模型：

```swift
struct Model: SmartCodableX {
    var name: String = ""
    @SmartFlat var profile: Profile?
}
struct Profile: SmartCodableX {
    var name: String = ""
    var age: Int = 0
}

// JSON: {"name": "Mccc", "age": 18}
// profile 从同级 JSON 中获取 name="Mccc", age=18
```

**@SmartCompact.Array 示例** — 容错数组解析：

```swift
struct Model: Decodable {
    @SmartCompact.Array var ages: [Int]
}

// JSON: {"ages": ["Tom", 1, {}, 2, 3, "4"]}
// 结果: ages = [1, 2, 3, 4]（无效元素被跳过，"4" 自动转换为 Int）
```

### 5. 继承支持

使用 `@SmartSubclass` 标注子类（需要 Swift 5.9+）：

```swift
class BaseModel: SmartCodableX {
    var name: String = ""
    required init() {}
}

@SmartSubclass
class StudentModel: BaseModel {
    var age: Int = 0
}
```

宏会自动生成 `CodingKeys`、`init(from:)` 和 `encode(to:)`。

> 低版本继承方案参见：[低版本继承指南](https://github.com/iAmMccc/SmartCodable/blob/main/Document/QA/QA2.md)

**子类实现协议方法** — 直接实现即可：

```swift
@SmartSubclass
class StudentModel: BaseModel {
    var age: Int?
    override static func mappingForKey() -> [SmartKeyTransformer]? {
        [ CodingKeys.age <--- "stu_age" ]
    }
}
```

**父类和子类同时实现协议方法** — 父类需使用 `class func`，子类调用 `super`：

```swift
class BaseModel: SmartCodableX {
    var name: String = ""
    required init() { }
    class func mappingForKey() -> [SmartKeyTransformer]? {
        [ CodingKeys.name <--- "stu_name" ]
    }
}

@SmartSubclass
class StudentModel: BaseModel {
    var age: Int?
    override static func mappingForKey() -> [SmartKeyTransformer]? {
        let trans = [ CodingKeys.age <--- "stu_age" ]
        if let superTrans = super.mappingForKey() {
            return trans + superTrans
        } else {
            return trans
        }
    }
}
```

### 6. 枚举支持

**普通枚举** — 遵循 `SmartCaseDefaultable`：

```swift
enum Sex: String, SmartCaseDefaultable {
    case man
    case woman
}
```

**带关联值的枚举** — 遵循 `SmartAssociatedEnumerable` 并通过 `mappingForValue()` 提供自定义转换器：

```swift
struct Model: SmartCodableX {
    var sex: Sex = .man
    static func mappingForValue() -> [SmartValueTransformer]? {
        [ CodingKeys.sex <--- SexTransformer() ]
    }
}

enum Sex: SmartAssociatedEnumerable {
    case man, woman, other(String)
}

struct SexTransformer: ValueTransformable {
    typealias Object = Sex
    typealias JSON = String
    func transformFromJSON(_ value: Any?) -> Sex? {
        guard let str = value as? String else { return nil }
        switch str {
        case "man": return .man
        case "woman": return .woman
        default: return .other(str)
        }
    }
    func transformToJSON(_ value: Sex?) -> String? { nil }
}
```

### 7. 解码回调与模型更新

**`didFinishMapping()`** — 解码完成后执行：

```swift
struct Model: SmartCodableX {
    var name: String = ""
    mutating func didFinishMapping() {
        name = "I am \(name)"
    }
}
```

**`SmartUpdater`** — 用新数据更新已有模型：

```swift
var model = Model.deserialize(from: initialData)!
SmartUpdater.update(&model, from: newData)
```

### 8. 容错兼容

SmartCodable 优雅地处理解析失败，确保整个模型永不崩溃：

```swift
let dict = ["number1": "123", "number2": "Mccc", "number3": "Mccc"]

struct Model: SmartCodableX {
    var number1: Int?
    var number2: Int?
    var number3: Int = 1
}
// 结果: Model(number1: 123, number2: nil, number3: 1)
```

- **类型转换兼容**：`"123"`（String）→ `123`（Int）自动转换
- **默认值填充**：转换失败时，使用属性声明时的初始值（`number3 = 1`）
- **可选类型处理**：转换失败时，可选属性返回 `nil`（`number2 = nil`）

**大数据解析性能建议**：解析大数据时，避免不必要的容错开销——使用 `CodingKeys` 排除不需要的属性，比 `@SmartIgnored` 效率更高。

### 9. 字符串化 JSON 自动解析

SmartCodable 能自动识别并解析字符串形式的 JSON：

```swift
struct Model: SmartCodableX {
    var hobby: Hobby?
}
// JSON: {"hobby": "{\"name\":\"sleep\"}"}
// hobby 被解析为 Hobby(name: "sleep")，而非原始字符串
```

### 10. 调试日志

```swift
SmartSentinel.debugMode = .verbose  // .none | .verbose | .alert
SmartSentinel.onLogGenerated { log in print(log) }
```

```
================================  [Smart Sentinel]  ================================
UserModel 👈🏻 👀
╆━ UserModel
┆┄ age    : 期望 Int，实际为 String — 已自动转换
┆┄ email  : 字段不存在 — 使用默认值 ""
====================================================================================
```



## 探索与贡献

| | |
|:--|:--|
| 🔧 [从 HandyJSON 迁移](https://github.com/iAmMccc/SmartCodable/blob/main/Explore%26Contribute/CompareWithHandyJSON.md) | 逐步迁移指南 |
| 🛠 [SmartModeler](https://github.com/iAmMccc/SmartModeler) | JSON → SmartCodable 模型生成工具 |
| 👀 [SmartSentinel](https://github.com/iAmMccc/SmartCodable/blob/main/Explore%26Contribute/Sentinel.md) | 实时解析日志查看器 |
| 💖 [参与贡献](https://github.com/iAmMccc/SmartCodable/blob/main/Explore%26Contribute/Contributing.md) | 支持 SmartCodable 的发展 |
| 🏆 [贡献者](https://github.com/iAmMccc/SmartCodable/blob/main/Explore%26Contribute/Contributors.md) | 核心贡献者名单 |

## 常见问题

- [👉 深入了解 SmartCodable](https://github.com/iAmMccc/SmartCodable/blob/main/Document/Usages/LearnMore.md)
- [👉 GitHub Discussions](https://github.com/iAmMccc/SmartCodable/discussions)
- [👉 如何测试](https://github.com/iAmMccc/SmartCodable/blob/main/Document/Usages/HowToTest.md)



## GitHub Stars

<p style="margin:0">
  <img src="https://starchart.cc/iAmMccc/SmartCodable.svg" alt="Stars" width="750">
</p>



## 加入社区 🚀

SmartCodable 是一个致力于让 Swift 数据解析更加健壮、灵活、高效的开源项目。欢迎所有开发者加入我们的社区！

<p>
  <img src="https://github.com/user-attachments/assets/7b1f8108-968e-4a38-91dd-b99abdd3e500" alt="JoinUs" width="700">
</p>
