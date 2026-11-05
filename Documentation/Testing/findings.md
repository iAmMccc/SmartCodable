# 回归案例与兼容边界

本页记录测试中的可复现案例及其适用边界。测试命令和支持域分别见 [重放指南](replay-guide.md) 与 [测试契约](contracts.md)。

## F-01：Int64 下溢

当 `value: Int64 = 77` 接收到十进制字符串 `-9223372036854775809` 时，该值超出 `Int64` 范围；strict、truncate 和 rounded 都应回退声明默认值 77。以前先转 `Double` 会将该输入舍入为 `Int64.min`，使越界值被误认为合法值。

当前实现按原始十进制数字和指数检查范围，再根据策略取整；`Tests/NumericSubprocessTests.swift` 通过子进程检查结果及进程状态，`Tests/NumericContractTests.swift` 覆盖相邻小数、科学计数法和其他定宽整数边界。

## F-02：JSON 布尔和数字的比较

Foundation 的 `NSNumber` 桥接可能使布尔和数值在普通转换中混淆。测试比较器先检查 CFBoolean 类型标签，有限数字使用 Decimal 比较；对象键顺序无关、数组顺序有意义，缺字段不同于 null。NaN 不属于合法 JSON。独立校准见 `Tests/JSONOracleTests.swift`。

## F-03：共享 decoder 的并发边界

固定配置下，同一 `SmartJSONDecoder` 的解码调用使用各自的解析标识和上下文；调用期间不要并发修改 decoder 的策略或 `userInfo`。调用方持有的引用值、闭包和自定义解码实现自行负责线程安全。`Tests/RootCauseFixTests.swift` 分别检查唯一会话标识和日志归属；相关过滤器见 [重放指南](replay-guide.md)。TSan 阴性不能证明任意调度安全。

## F-04：属性测试与 fuzzing 的范围

`Tools/PropertyTests` 使用锁定的 PropertyBased 依赖，失败时可用 seed 与缩减输入重放。`Fuzzing/` 提供原始数据和有界结构化两个目标；短跑不代表长期稳定性，当前链接方式不包含 ASan 或 TSan。详见 [Fuzzing 指南](../../Fuzzing/README.md)。

## F-05：覆盖率的限制

覆盖报告需要与对应的测试退出状态、工具链、源码范围和 profile 一起解释；失败运行及未合并的子进程 profile 不能作为完整通过运行的覆盖证据。见 [覆盖率与变异测试指南](coverage-and-mutation.md)。

## F-06：普通数组元素失败

普通嵌套数组中，无法解码的元素会使错误向上传播，整个属性回退到声明默认值。例如 `[Child]` 对 `[{"id":1}, null, {"id":2}]` 回退 `[]`；`{}` 是可解码对象，会使用该元素的声明默认值。该默认行为与 7.0.1 相同；需要跳过无效元素时使用 `@SmartCompact.Array`。

`Tests/CompatibilityReviewTests.swift` 同时检查 null、非对象和可成功解码的默认对象；`Tests/Branch702ReviewRegressionTests.swift` 检查回调和回退。

## F-07：macOS 颜色编码

`@SmartHexColor` 在 macOS 上对由 calibrated/generic RGB 创建的颜色直接读取分量；其他颜色转到 device RGB 后读取。通道转换使用四舍五入。对于输入 `"FF0000"` 和 `.rrggbb(.hash)`，编码预期为 `"#FF0000"`。系统颜色和其他颜色空间仍受系统转换影响。

`Tests/Branch702ReviewRegressionTests.swift` 检查重命名键、12 种格式、通道往返及代码创建的颜色；这些测试不替代所有系统颜色空间的验证。

## F-09：可选模型数组回调

`[Child?]` 接收 `[{"id":1}, null, {"id":2}]` 时保留 nil 的位置；非 nil 元素默认不执行 `didFinishMapping`。例如回调会给 id 加 10 时，结果仍为 `[1, nil, 2]`。非对象元素使嵌套数组属性回退声明默认值。字典模型值也不在字典解包路径中执行完成回调；具体入口规则见 [兼容性选项](../../Document/CompatibilityOptions.md#model-completion-callbacks)。

`Tests/Branch702ReviewRegressionTests.swift` 检查位置和回调计数；`Tests/AuditRegressionTests.swift` 检查字典元素。

## F-10：Swift 模块路径

SwiftPM 的 `SmartCodable.swiftmodule` 可以是文件或目录。`Fuzzing/run.sh` 使用路径存在性检查识别两种形式，而不是仅接受普通文件；目标运行与单输入重放方法见 [Fuzzing 指南](../../Fuzzing/README.md)。
