# SmartCodable 测试契约

基线：`bc1522f6b635128ea992331867fe65f231492dc0`；本轮验证包含 `7.0.2` 工作区尚未提交的修复。以下性质仅在列出的支持域内成立。预期值来自输入整数、模型声明或 Foundation JSON 类型标签，不调用被测 `JSONValue`/`Patcher` 计算预期。表内 `Core/` 均指 `Sources/SmartCodable/Core/`。

| ID | 行为及支持域 | 排除/待确认 | 独立判定与测试 | 相关源码 |
| --- | --- | --- | --- | --- |
| NUM-01 | Int8、UInt8 所有合法值以 JSON 数字或规范十进制字符串输入，保留精确值；Int64、UInt64 的 min/max、相邻值及 2^53 附近字符串同理 | 非规范文本、超大任意精度数不属于无损域 | 原始生成整数；`Tests/NumericContractTests.swift`（1024 次有限域解码及宽整数边界） | `Core/JSONDecoder/Patcher/Patcher+Transformer.swift`、`Core/JSONDecoder/Decoder/Impl/JSONDecoderImpl+Unwrap.swift` |
| NUM-02 | Int64/UInt64 越界十进制字符串不 trap；失败按模型声明默认值回退。strict/truncate/rounded 分别检查 | IEEE 754 舍入不能使数学上越界值变为合法整数；小数取整须另列规则 | 原样十进制文本传入隔离 XCTest 子进程，父进程检查信号/退出码/输出；`Tests/NumericSubprocessTests.swift`。下溢曾复现失败，现已修复并保留回归，见 findings | `Core/JSONDecoder/Patcher/Patcher+Transformer.swift` |
| BOOL-01 | Bool 支持 JSON true/false、0/1、已明确的 YES/NO、true/false 文本；2、-1、maybe 回退声明默认值 | 不把任意非零数视为 true | 独立布尔期望表；`Tests/NumericContractTests.swift` | `Core/JSONDecoder/Patcher/Patcher+Transformer.swift` |
| DEF-01 | 同名字段的声明默认值属于当前模型 owner；缺失、null、错误类型不能串到其它模型 | 自定义 `CodingKeys` rawValue 与属性名不同时，需显式 `SmartDefaultValueKeyMapping` | 模型声明 17/91/73 等不同于零值的常量；`Tests/DecodingContextTests.swift`、`Tests/StructuredSemanticTests.swift`、`Tools/PropertyTests` | `Core/JSONDecoder/Decoder/DecodingSnapshot.swift` |
| ARR-01 | 普通数组无效单元素保持位置并回退该元素；`@SmartCompact.Array` 则跳过无效元素 | 两种数组语义不同，不可共用一个断言 | `[first, null, first+1]` 的显式期望；`Tests/DecodeEdgeCaseTests.swift`、`Tests/AuditRegressionTests.swift`、`Tests/StructuredSemanticTests.swift` | `Core/JSONDecoder/Decoder/Impl/JSONDecoderImpl+UnkeyedContainer.swift`、`Core/PropertyWrapper/SmartCompact/SmartCompactArray.swift` |
| MAP-01 | 候选 key 按声明顺序选首个非 null；嵌套路径支持有明确的层级与别名 | 冲突或重复 JSON key、子模型更新别名归一化没有全域保证 | 外部键优先级表；`Tests/AuditRegressionTests.swift` | `Core/JSONDecoder/Decoder/KeysMapper.swift`、`Core/SmartCodable/SmartUpdater.swift` |
| WRAP-01 | Ignored/Flat/Any 包装器声明、编码标志与默认值在同一次模型入口中归属正确 | 有意不编码的字段在 `SmartUpdater` 需显式 `preserving` | 声明值与输出字段表；`Tests/SmartIgnoredTests.swift`、`Tests/SmartFlatTests.swift`、`Tests/AuditRegressionTests.swift` | `Core/PropertyWrapper/`、`Core/JSONDecoder/Decoder/DecodingSnapshot.swift` |
| IO-01 | Data、String、Dict 对共同支持的合法 JSON 对象有相同已知字段结果 | 原生 Swift 非 JSON 值、精度歧义和顶层 fragment 不纳入三入口共同域 | 同一数学整数、各入口生成 JSON，`Tools/PropertyTests/Tests/PropertyTests/ContractProperties.swift` | `Core/JSONExtractor/JSONExtractor.swift`、`Core/JSONDecoder/Decoder/SmartJSONDecoder.swift` |
| ENC-01 | 无损子集中的简单 Int 模型 encode/decode 后保留模型值 | Ignored、截断、日期精度、非幂等 callback 明确排除 | 原始整数与编解码后的字段比较；`Tools/PropertyTests`、`Tests/DynamicEncodingRegressionTests.swift` | `Core/JSONEncoder/`、`Core/SmartCodable/` |
| CON-01 | 独立 decoder 与全局日志/选项并发测试不出现数据竞争，字段与默认引用归属正确 | TSan 阴性不等于任意调度安全 | 值、引用身份、TSan；`Tests/DecodingContextTests.swift`、`Tests/GlobalOptionsConcurrencyTests.swift` | `Core/JSONDecoder/Decoder/`、`Core/Sentinel/` |
| CON-02 | 同一 `SmartJSONDecoder` 实例的并发支持范围 | **契约待确认**：`@unchecked Sendable` 与 `userInfo` 修改需要分别核实；一次诊断未观察到 race 不构成保证 | `Tools/Diagnostics/Sources/SharedDecoderProbe/main.swift`，手工 TSan 运行，不作为通过门禁 | `Core/JSONDecoder/Decoder/SmartJSONDecoder.swift` |
| RAW-01 | 0–255 的单字节与 `{byte}` 形态各 256 份有界 Data 调用不能导致进程崩溃；另有有效 JSON seed 必须真正进入模型解码 | 语法错误可以抛出；有限 smoke 不证明超大资源输入安全 | `Tests/RawInputSmokeTests.swift`，512 次短输入；`Fuzzing/Sources/RawInput.swift` 已完成本地覆盖引导短跑 | `Core/JSONDecoder/Decoder/SmartJSONDecoder.swift` |
| FUZZ-01 | 结构化字节映射到已编译 Int16 模型：有效数值/字符串保留精确值，缺失/无效值回退声明默认值 | 输入长度 3–64 字节；仅此模型形状和策略；32 次短跑不代表长期稳定性 | `Fuzzing/Sources/StructuredSemantic.swift` 的独立期望与失败 `fatalError`；人工错误校准验证保存 crash/新进程重放 | `Core/JSONDecoder/Patcher/Patcher+Transformer.swift` |
| API-01 | 仅 `import SmartCodable` 能使用 decode-only、encode-only、组合模型及基础类模型 | 宏继承需单独 SmartCodableMacro；此 fixture 不验证宏 | 独立本地包 `Tools/PublicAPISmoke`，6 条运行时检查，无 `@testable` | `Core/SmartCodable/`、`Package.swift` |
| ORACLE-01 | JSON Boolean 与数字不等；大整数不经 Double 比较；对象键无序、数组有序、缺字段与 null 不等 | NaN 非合法 JSON；`-0 == 0` 限定整数数学域 | Foundation 标签表示 `ReferenceJSON` 及比较器自测；`Tests/JSONOracleTests.swift` | 测试代码 `Tests/TestSupport.swift` |

生成式测试的明确排除项：随机输入不代表所有 Swift 模型形状；类型转换、Ignored 字段及非幂等 callback 不要求与 Foundation 解码器或原始 JSON 逐字节相等。`Tools/PropertyTests` 使用 PropertyBased 2.0.1 随机探索；失败日志给出 seed 和缩减输入。正常通过运行不记录可重放 seed；确定性回放靠 `Tests/StructuredSemanticTests.swift` 的 `lcg-v1`、固定 seed 和具体失败输入。
