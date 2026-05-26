# SmartCodable 技术说明

本文档面向项目的协作开发者，帮助你快速理解项目的架构、设计意图和开发注意事项。

---

## 一、项目定位

SmartCodable 是基于 Swift 原生 Codable 协议的 JSON 解析库。核心目标是解决 Codable 在生产环境中的容错性问题——原生 Codable 在遇到字段缺失、类型不匹配、null 值时会直接抛异常导致整个模型解析失败，SmartCodable 则通过默认值回退、自动类型转换等机制实现优雅降级。

**技术选型原则：** 不使用 Runtime 反射（区别于 HandyJSON），不依赖第三方序列化框架（区别于 SwiftyJSON），完全基于 Codable 协议扩展。唯一的运行时反射是 `Mirror`，仅用于获取属性默认值。

---

## 二、模块结构

```
SmartCodable (主模块)
├── Core/
│   ├── SmartCodable/           # 核心协议：SmartDecodable, SmartEncodable
│   ├── JSONDecoder/            # 自定义解码器（完整实现，非包装系统 JSONDecoder）
│   │   ├── Decoder/            # SmartJSONDecoder 入口 + JSONDecoderImpl 核心
│   │   ├── Impl/               # KeyedContainer / UnkeyedContainer / SingleValueContainer
│   │   ├── Patcher/            # 类型转换 + 默认值提供
│   │   └── Cache/              # 解码缓存（快照机制）
│   ├── JSONEncoder/            # 自定义编码器
│   ├── PropertyWrapper/        # 属性包装器（SmartAny, SmartIgnored, SmartFlat 等）
│   ├── Transformer/            # 值转换器（日期、颜色、URL 等）
│   ├── Sentinel/               # 调试日志系统
│   └── JSONValue/              # 内部 JSON 中间表示

SmartCodableMacros (编译器插件，Swift 5.9+)
└── SmartSubclassMacro          # @SmartSubclass 宏实现

SmartCodableInherit (桥接模块)
└── 宏声明的 public 接口
```

**两份 Package.swift 的原因：** `Package.swift`（Swift 5.8）不含宏依赖，`Package@swift-5.9.swift` 包含 SwiftSyntax 依赖。这样 Swift 5.9 以下的项目也能使用核心功能。

---

## 三、核心解码流程

用户调用到最终输出的完整链路：

```
Model.deserialize(from: json)                    // SmartDecodable.swift
  ↓
JSONExtractor.extract()                          // 解析输入，支持 designatedPath 嵌套路径提取
  ↓
SmartJSONDecoder.smartDecode(type, from: data)    // SmartJSONDecoder.swift
  ↓
输入数据 → JSONValue（内部中间表示）                // JSONValue.swift
  ↓
JSONDecoderImpl.unwrap(as: type)                  // JSONDecoderImpl+Unwrap.swift
  ├── 特殊类型直接处理：Date, Data, URL, Decimal, CGFloat, Dictionary
  └── 普通类型：
      ├── cache.cacheSnapshot()                   // 创建快照，记录类型信息
      ├── type.init(from: self)                   // 触发 Codable 标准流程
      │   ↓
      │   KeyedContainer 初始化                    // JSONDecoderImpl+KeyedContainer.swift
      │     ├── _convertDictionary()              // 应用 Key Mapping
      │     │   ├── SmartKeyDecodingStrategy      // snake_case → camelCase 等
      │     │   └── KeysMapper.convertFrom()      // 自定义 mappingForKey()
      │     └── 逐属性解码：
      │         ├── 1. 检查 ValueTransformer      // mappingForValue() 自定义转换
      │         ├── 2. 尝试标准解码
      │         ├── 3. 类型转换 Patcher            // Int↔String, Bool↔Int 等
      │         └── 4. 默认值回退 Cache             // Mirror 反射获取的初始值
      └── cache.removeSnapshot()                  // 清理快照
  ↓
didFinishMapping()                                // 用户回调，可做后处理
```

### 关键设计：解码永不抛异常

与原生 Codable 最大的区别在于错误处理策略。当某个属性解码失败时：

1. **先尝试类型转换**（Patcher）：比如 JSON 传了 `"123"` 但属性类型是 `Int`，自动转换
2. **再回退到默认值**（DecodingCache）：使用属性声明时的初始值
3. **最后记录日志**（SmartSentinel）：不抛异常，不中断解析，但记录问题

这个策略是整个项目的核心设计意图。

---

## 四、默认值机制（DecodingCache）

这是 SmartCodable 最核心的机制，也是最需要理解的部分。

### 工作原理

```
解码开始
  ↓
cacheSnapshot(for: Model.self)          // 记录类型，但不立即反射
  ↓
某属性解码失败
  ↓
initialValueIfPresent(forKey: "name")   // 首次访问时触发 Mirror 反射
  ↓
populateInitialValues()                  // 创建 Model.init()，用 Mirror 提取所有属性初始值
  ↓
返回 snapshot.initialValues["name"]     // 即用户声明的 var name: String = "默认值" 中的 "默认值"
  ↓
解码结束
  ↓
removeSnapshot(for: Model.self)          // 清理
```

### 快照栈机制

嵌套模型解码时，快照按栈（数组）管理。查找时通过 `codingPath` 匹配：

```swift
struct A: SmartCodable {       // snapshot[0]: codingPath = []
    var b: B = B()             // snapshot[1]: codingPath = ["b"]
}
struct B: SmartCodable {
    var name: String = "hello" // 查找 snapshot where codingPath == ["b"]
}
```

### 属性包装器的特殊处理

属性包装器在 Swift 中存储为 `_propertyName`（下划线前缀）。DecodingCache 会同时检查 `key` 和 `_key`，并通过 `extractWrappedValue()` 提取包装器内的实际值。

---

## 五、Key Mapping 系统

### 用法

```swift
struct Model: SmartCodable {
    var userName: String = ""

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [CodingKeys.userName <--- "user_name"]          // 单个映射
        [CodingKeys.userName <--- ["user_name", "name"]] // 多候选，首个非 null 的胜出
    }
}
```

### 嵌套路径

支持点分隔路径直接提取嵌套值：

```swift
// JSON: {"data": {"user": {"name": "Mccc"}}}
CodingKeys.name <--- "data.user.name"
```

实现在 `KeysMapper.getValue(forKeyPath:)` 中，按 `.` 分割后逐层查找。

### 注意事项

- 映射在 `KeyedContainer` 初始化时一次性应用（`_convertDictionary`）
- 多候选映射按数组顺序尝试，**第一个非 null 值胜出**
- Key Mapping 和全局 `SmartKeyDecodingStrategy`（如 snake_case）会叠加生效

---

## 六、Value Transformer 系统

用于自定义值的编解码逻辑，优先级高于默认的类型转换。

```swift
struct Model: SmartCodable {
    var date: Date = Date()

    static func mappingForValue() -> [SmartValueTransformer]? {
        [CodingKeys.date <--- SmartDateFormatTransformer(format: "yyyy-MM-dd")]
    }
}
```

### 解码优先级

```
1. ValueTransformer（mappingForValue）    ← 最高优先级
2. 标准 Codable 解码
3. Patcher 类型转换（Int↔String 等）
4. DecodingCache 默认值回退              ← 最低优先级
```

### 内置 Transformer

| Transformer | 用途 |
|-------------|------|
| `SmartDateTransformer` | 时间戳 ↔ Date |
| `SmartDateFormatTransformer` | 自定义格式字符串 ↔ Date |
| `SmartDataTransformer` | Base64 字符串 ↔ Data |
| `SmartURLTransformer` | 字符串 ↔ URL（支持自动 URL 编码） |
| `SmartHexColorTransformer` | 十六进制字符串 ↔ UIColor/NSColor |
| `FastTransformer<Object, JSON>` | 通用闭包转换器 |

---

## 七、属性包装器

| 包装器 | 用途 | 遵循 PropertyWrapperable |
|--------|------|--------------------------|
| `@SmartAny` | 支持 `Any`、`[Any]`、`[String: Any]` 类型 | 是 |
| `@SmartIgnored` | 跳过该属性的解码（可选是否参与编码） | 是 |
| `@SmartFlat` | 将嵌套对象的属性扁平化到父模型 | 是 |
| `@SmartDate` | 多格式日期自动解析 | 是 |
| `@SmartHexColor` | 十六进制颜色字符串解析 | 是 |
| `@SmartPublished` | 配合 Combine 的 ObservableObject 使用 | 是 |
| `@SmartCompact.Array` | 容错数组解析，跳过无效元素 | 否（设计如此） |
| `@SmartCompact.Dictionary` | 容错字典解析，跳过无效键值对 | 否（设计如此） |

**SmartCompact 不遵循 PropertyWrapperable 是设计决策**：它们有独立完整的 Codable 实现，不需要框架的回调机制。

---

## 八、继承支持（@SmartSubclass）

Swift 的 Codable 不自动处理子类属性。`@SmartSubclass` 宏在编译期生成：

- `CodingKeys` 枚举（仅包含子类自身的属性）
- `init(from: Decoder)`（先调 super，再解码子类属性）
- `encode(to: Encoder)`（先调 super，再编码子类属性）
- `required init()`（如果不存在）

```swift
class Base: SmartCodable {
    var name: String = ""
    required init() {}
}

@SmartSubclass
class Sub: Base {
    var age: Int = 0    // 宏会自动生成解码/编码逻辑
}
```

**注意：** 宏依赖 SwiftSyntax，通过独立的 subspec/target 隔离。不使用继承的项目不需要引入。

---

## 九、调试系统（SmartSentinel）

```swift
// 开启日志
SmartSentinel.debugMode = .verbose  // .none | .verbose | .alert

// 监听日志
SmartSentinel.onLogGenerated { log in
    print(log)
}
```

- `.verbose`：记录所有问题（缺失字段、null 值、类型不匹配）
- `.alert`：仅记录类型不匹配（更严重的问题）
- `.none`（默认）：不记录，零开销

日志输出格式：
```
================================  [Smart Sentinel]  ================================
ModelName 👈🏻 👀
╆━ ClassName
┆┄ fieldName    : 类型不匹配，期望 Int，实际 String
====================================================================================
```

---

## 十、内部类型：JSONValue

SmartCodable 不直接操作 `Data` 或 `[String: Any]`，而是先转换为内部的 `JSONValue` 枚举：

```swift
enum JSONValue: Equatable {
    case string(String)
    case number(String)    // 用 String 存储数字，避免精度丢失
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])
}
```

**为什么数字用 String 存储？** 避免 `Double(1.0)` 和 `Int(1)` 在 JSON 层面的精度歧义。转换到具体类型时再按需解析。

---

## 十一、全局配置

```swift
// 数字转换策略
SmartCodableOptions.numberStrategy = .strict    // 默认：严格，3.14 → Int 返回 nil
SmartCodableOptions.numberStrategy = .truncate  // 截断：3.14 → Int 返回 3
SmartCodableOptions.numberStrategy = .rounded   // 四舍五入：3.6 → Int 返回 4

// null 处理
SmartCodableOptions.ignoreNull = true           // 默认：忽略 null，保持属性默认值
SmartCodableOptions.ignoreNull = false          // 将 null 作为值传递给 Any 类型
```

这两个配置是全局的（已加锁保护线程安全），会影响所有解码操作。通常在 App 启动时设置一次。

---

## 十二、开发注意事项

### 必须遵守

1. **不破坏公共 API**：`SmartDecodable`、`SmartEncodable`、所有属性包装器的公开接口不能改签名
2. **向后兼容**：最低支持 Swift 5.0 / iOS 13+，不能使用高版本独占的 API
3. **不新增 SwiftSyntax 依赖**：宏功能已隔离到独立 target，核心模块不能依赖 SwiftSyntax

### 代码约定

4. **DecodingCache 的快照必须成对调用**：`cacheSnapshot()` 和 `removeSnapshot()` 必须配对，否则快照栈会泄漏。当前在 `unwrap()` 方法中管理，修改时注意异常路径
5. **Patcher 中的类型转换要双向安全**：比如 String → Int，必须验证字符串确实是合法数字，不能静默返回 0
6. **属性包装器的存储名有下划线前缀**：Swift 编译器将 `@SmartAny var name` 存储为 `_name`，DecodingCache 中需要处理这个映射
7. **KeyedContainer 中的 `_convertDictionary()` 只执行一次**：在容器初始化时调用，之后的属性解码都基于转换后的字典

### 测试相关

8. **现有测试有编译问题**：`Tests/Example.swift` 中 `SmartCodable` 类型名与模块名冲突（Swift 的已知问题），`swift test` 会失败但 `swift build` 正常。后续需修复
9. **修改核心解码逻辑后**：至少手动验证——简单模型、嵌套模型、数组模型、可选字段、类型不匹配、缺失字段这几个场景

### 性能相关

10. **Mirror 反射是懒加载的**：`DecodingCache` 只在首次需要默认值时才反射，不是每次解码都反射
11. **SafeDictionary 使用 NSLock**：Sentinel 的日志字典有锁保护，在 `debugMode == .none` 时不会触碰
12. **SmartSentinel 的日志守卫**：所有日志方法入口都有 `guard debugMode != .none else { return }`，Release 环境零开销（前提是 debugMode 保持默认的 `.none`）
