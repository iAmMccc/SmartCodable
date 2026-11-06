# 测试运行与反例重放

从仓库根目录执行以下命令。根包使用 Swift tools 5.9；独立属性测试包使用 Swift tools 6.1 和锁定的 PropertyBased 依赖。SwiftPM 默认使用各包的 `.build` 目录。

## 构建与测试

```sh
swift build
swift test
swift test -c release
swift test --filter NumericContractTests
swift test --filter NumericSubprocessTests
swift test --filter JSONOracleTests
swift test --filter StructuredSemanticTests
swift test --filter RawInputSmokeTests
swift test --filter Branch702ReviewRegressionTests
swift test --filter AuditRegressionTests
swift test --filter CompatibilityReviewTests
swift test --filter RootCauseFixTests
swift test --filter UnkeyedDecodeIfPresentContractTests
swift test --filter CompactDynamicKeyTests
swift test --filter LegacyAPICompatibilityTests
swift test --filter CompactOptionalCompatibilityTests
swift test --filter DynamicEncodingErrorBoundaryTests
swift test --filter LegacyHexIntegerTests
swift test --package-path Tools/PropertyTests
swift run --package-path Tools/PublicAPISmoke PublicAPISmoke
```

过滤测试时检查实际执行数；过滤器没有匹配项也可能退出 0。`NumericSubprocessTests` 的子入口仅由父测试启动，在普通 XCTest 进程中按设计跳过；子进程边界测试仅在 macOS 上编译。公开 API fixture 不验证宏继承功能。各测试支持域与独立预期见 [测试契约](contracts.md)。

`LegacyAPICompatibilityTests.swift` 仅使用 7.0.1 已有调用方式，不启用新增策略。
它可以原样放入 7.0.1 与 7.0.2 的隔离源码副本，验证默认接受范围、null、声明默认值、
模型回调及自定义编码的副作用和错误边界。两边使用相同工具链、测试源码与输入；
这组定向对照不替代任一版本的全量测试。精度与上下文隔离等已修正缺陷仍由各自回归测试验证，
不要求恢复旧版错误结果。扩展策略另由对应测试显式启用并断言。

比较 API 时使用明确的 Git 引用，避免同名分支和标签歧义：

```sh
swift package diagnose-api-breaking-changes refs/tags/7.0.1
```

## 数值边界

`Tests/NumericSubprocessTests.swift` 把原样十进制输入和策略传入独立进程，检查退出类型、状态及输出，避免 trap 杀死主测试进程。例：`Int64` 声明默认值为 77，输入 `-9223372036854775809` 时，strict、truncate 和 rounded 均回退到 77。有效边界及上溢也有对照。复现见 [F-01](findings.md#f-01int64-下溢)。

## 属性测试与重放

`Tools/PropertyTests` 运行随机性质；失败时按输出的 seed 和缩减输入重放。该工具的 `.fixedSeed` 用于重放失败，而非正常通过的测试。确定性输入和固定 seed 另见 `Tests/StructuredSemanticTests.swift`；失败信息包含迭代号及具体 payload。有限样本和随机运行都不代表所有模型形状。

## 并发、内存与覆盖

```sh
swift test --sanitize=thread --filter GlobalOptionsConcurrencyTests
swift test --sanitize=thread --filter DecodingContextTests.testConcurrentIndependentDecodersFallbackDefaultsStayIsolated
swift test --sanitize=thread --filter RootCauseFixTests.testConcurrentSharedDecoderSessionsStayDistinctWithFixedConfiguration
swift test --sanitize=thread --filter RootCauseFixTests.testSharedDecoderConcurrentLogsKeepOneSessionPerCall
swift run --package-path Tools/Diagnostics --sanitize=thread SharedDecoderProbe
swift test --sanitize=address --filter NumericContractTests
swift test --enable-code-coverage
```

TSan 和 ASan 应分别运行；阴性结果不能证明所有调度或输入安全。同一 decoder 并发使用的固定配置边界见 [兼容性选项](../../Document/CompatibilityOptions.md#shared-decoder-configuration)。覆盖结果的解释见 [覆盖率与变异测试指南](coverage-and-mutation.md)。

## Fuzzing 与 iOS 示例

macOS 的覆盖引导目标、依赖与种子重放见 [Fuzzing 指南](../../Fuzzing/README.md)。短跑仅是工具链和有限输入检查，不包含 ASan 或 TSan。

可用已安装的 iOS Simulator 编译 ExampleApp，例如：

```sh
xcodebuild -project Example/ExampleApp/ExampleApp.xcodeproj -scheme ExampleApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

选择已安装的设备名称。构建通过不代表已运行页面；可运行页面显示输入、API、期望、实际和判定，自定义输入没有预设固定期望。继承说明页没有运行按钮。
