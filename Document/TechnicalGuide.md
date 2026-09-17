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
│   │   ├── Decoder/            # SmartJSONDecoder 入口 + JSONDecoderImpl 核心 + DecodingSnapshot（模型上下文）
│   │   ├── Impl/               # KeyedContainer / UnkeyedContainer / SingleValueContainer
│   │   ├── Patcher/            # 类型转换 + 默认值提供
│   │   └── Cache/              # 编码缓存（编码侧快照机制）
│   ├── JSONEncoder/            # 自定义编码器
│   ├── PropertyWrapper/        # 属性包装器（SmartAny, SmartIgnored, SmartFlat 等）
│   ├── Transformer/            # 值转换器（日期、颜色、URL 等）
│   ├── Sentinel/               # 调试日志系统
│   └── JSONValue/              # 内部 JSON 中间表示

```

> 类继承能力（`@SmartSubclass`）已抽离到独立的配套库 [SmartCodableMacro](https://github.com/iAmMccc/SmartCodableMacro)，避免本库引入 swift-syntax 依赖。

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
      └── decoderForEntry(type)                   // 为本次类型入口准备局部上下文
          ├── modelSnapshot = DecodingSnapshot(objectType:)  // Smart 模型每次入口新建
          └── type.init(from: entry)              // 触发 Codable 标准流程
              ↓
              KeyedContainer 初始化               // JSONDecoderImpl+KeyedContainer.swift
                ├── snapshot = impl.modelSnapshot // 容器创建时固定绑定所属模型
                ├── _convertDictionary()          // 应用 Key Mapping（owner 来自固定 snapshot）
                │   ├── SmartKeyDecodingStrategy  // snake_case → camelCase 等
                │   └── KeysMapper.convertFrom()  // 自定义 mappingForKey()
                └── 逐属性解码：
                    ├── 1. 检查 ValueTransformer // mappingForValue() 自定义转换（读自身 snapshot）
                    ├── 2. 尝试标准解码
                    ├── 3. 类型转换 Patcher       // Int↔String, Bool↔Int 等
                    └── 4. 默认值回退 snapshot    // Mirror 反射获取的初始值
  ↓
didFinishMapping()                                // 用户回调，可做后处理
```

### 关键设计：解码永不抛异常

与原生 Codable 最大的区别在于错误处理策略。当某个属性解码失败时：

1. **先尝试类型转换**（Patcher）：比如 JSON 传了 `"123"` 但属性类型是 `Int`，自动转换
2. **再回退到默认值**（DecodingSnapshot）：使用属性声明时的初始值
3. **最后记录日志**（SmartSentinel）：不抛异常，不中断解析，但记录问题

这个策略是整个项目的核心设计意图。

---

## 四、默认值机制（解码上下文显式绑定）

这是 SmartCodable 最核心的机制，也是最需要理解的部分。

### 工作原理

默认值与映射元数据由 `DecodingSnapshot` 承载：**某一次模型解码的上下文**。
每个新的、框架可观察的 Smart 模型初始化入口都会创建自己的实例，不按类型、
路径或作用域去重；`objectType` 构造后不可变。

```
unwrap(as: Model.self) / decodeInPlace / singleValue decode
  ↓
decoderForEntry(type)                    // 为本次入口准备局部 decoder 视图
  ↓
modelSnapshot = DecodingSnapshot(objectType: Model.self)   // 记录类型，但不立即反射
  ↓
执行 Model.init(from: entry)
  ↓
某属性解码失败
  ↓
snapshot.initialValueIfPresent(forKey:)  // 首次访问时触发 Mirror 反射（含父类递归）
  ↓
返回声明初始值                           // 即 var name: String = "默认值" 中的值
```

解码完成后该上下文随 decoder 视图一起释放，框架不持有全局注册表。

### 容器固定绑定

KeyedContainer 在创建时绑定 `impl.modelSnapshot`，此后不再变化：子模型正在
解码、抛错、或宿主在回调中同步回读已持有的容器，父容器的归属都不变。
因此异常路径无需任何“恢复 owner”的动作，也不会出现 SmartFlat 平铺期间
子模型默认值污染父容器的问题。

`codingPath` 仍只表示 JSON 解码位置（用于错误路径与既有结构分支），不参与
模型归属判断。

### 属性边（PropertyDecodingContext）

模型容器的每个属性值视图携带一条明确的属性边：`(宿主模型上下文, 规范属性 key)`。
它只服务“当前整属性”的合法消费者（恢复完整包装器声明、当前属性的整体
Value Transformer），不提供向父级链式搜索的能力，也不能当作子对象的字段表：

- 数组元素、字典数据键、手写 `nestedContainer` / `superDecoder` 进入的原始
  子结构，属性边被清空，不得借用宿主字段表。
- 未知的普通 `Codable` 子对象不继承上层模型上下文（否则同名字段会串值）；
  其缺失字段按 Patcher 类型兜值处理。

### 属性包装器的特殊处理

属性包装器在 Swift 中存储为 `_propertyName`（下划线前缀）。snapshot 会同时
检查 `key` 和 `_key`，并通过 `extractWrappedValue()` 提取包装器内的实际值；
`declaredWrapper(forKey:as:)` 则返回完整的包装器声明，保留 `SmartIgnored.isEncodable`
等自身配置。

双协议包装器（同时遵循 `PropertyWrapperable` 与 `SmartDecodable`）经
`unwrap` 入口先绑定包装器自身的上下文；内层模型必须通过协作接口获得自己的
新上下文：

```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    marker = try container.decode(Int.self, forKey: .marker)
    wrappedValue = try Self.decodeWrappedValue(from: decoder)
}
```

该接口对普通 Decoder 仍等价于 `Value(from: decoder)`；对 SmartCodable 则派生
一个绑定到内层模型的新解码视图。旧包装器继续兼容；但若仍直接调用
`Value(from:)`，wrapper 与 inner 共享同一个解码视图，框架没有可观察信息区分
这次调用，表现为确定性的 wrapper-first 语义。需要严格内外隔离的自定义包装器
必须使用 `decodeWrappedValue(from:)` 或容器 decode 入口。

普通第三方包装器（仅 `PropertyWrapperable`）直接执行 `Value(from: decoder)`
时，入口会为内层模型建立局部兼容上下文，保证内层声明默认值可用；该绑定只
服务这一次直接初始化，下一次显式 `decode(Value.self)` 仍会新建上下文，
两次独立初始化不会共享可变默认对象。

需要恢复包装器自身配置（例如 `SmartIgnored.isEncodable`）时，必须从属性边
指向的宿主声明恢复完整包装器，不能只提取 `wrappedValue`，也不能从其他
嵌套模型的同名属性推断状态。

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
4. DecodingSnapshot 默认值回退            ← 最低优先级
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

类继承能力已迁移至独立仓库 [SmartCodableMacro](https://github.com/iAmMccc/SmartCodableMacro)，请参考该仓库文档。

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
2. **向后兼容**：包声明为 Swift tools 5.9，最低部署目标 iOS 13+ / macOS 10.15+，不能使用更高版本独占的 API
3. **不新增 SwiftSyntax 依赖**：宏功能已隔离到独立 target，核心模块不能依赖 SwiftSyntax

### 代码约定

4. **解码上下文通过类型入口统一建立**：`unwrap(as:)` / `decodeInPlace(_:)` 内部经 `decoderForEntry` 为每次可观察初始化准备局部上下文；不要在调用方手工构造或复用 `DecodingSnapshot`，也不要按 `(类型, codingPath)` 缓存上下文
5. **Patcher 中的类型转换要双向安全**：比如 String → Int，必须验证字符串确实是合法数字，不能静默返回 0
6. **属性包装器的存储名有下划线前缀**：Swift 编译器将 `@SmartAny var name` 存储为 `_name`，DecodingSnapshot 中需要处理这个映射
7. **KeyedContainer 中的 `_convertDictionary()` 只执行一次**：在容器初始化时调用，之后的属性解码都基于转换后的字典

### 测试相关

8. **现有测试有编译问题**：`Tests/Example.swift` 中 `SmartCodable` 类型名与模块名冲突（Swift 的已知问题），`swift test` 会失败但 `swift build` 正常。后续需修复
9. **修改核心解码逻辑后**：至少手动验证——简单模型、嵌套模型、数组模型、可选字段、类型不匹配、缺失字段这几个场景

### 性能相关

10. **Mirror 反射是懒加载的**：`DecodingSnapshot` 只在首次需要默认值时才反射，不是每次解码都反射；同一上下文内重复查询复用同一份引用，跨上下文互不共享
11. **SafeDictionary 使用 NSLock**：Sentinel 的日志字典有锁保护，在 `debugMode == .none` 时不会触碰
12. **SmartSentinel 的日志守卫**：所有日志方法入口都有 `guard debugMode != .none else { return }`，Release 环境零开销（前提是 debugMode 保持默认的 `.none`）
