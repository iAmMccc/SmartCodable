# 测试运行与反例重放

从 `SmartCodable/` 仓库根目录执行。根包仍为 Swift tools 5.9，不需要 PropertyBased 才能运行常规 XCTest。以下命令只读依赖与源码，不会修改生产行为。`Tools/PropertyTests` 的首次编译需要解析固定版本的远程测试依赖，`Tools/Diagnostics` 的 TSan 首次编译也可能显著慢于缓存运行。

## 快速检查

```sh
swift build
swift test --filter NumericContractTests
swift test --filter JSONOracleTests
swift test --filter StructuredSemanticTests
swift test --filter RawInputSmokeTests
swift run --package-path Tools/PublicAPISmoke PublicAPISmoke
```

修复后分别执行了 8、7、3、1 条 XCTest；RawInputSmokeTests 另对 512 个短字节输入做语法/崩溃烟测，不能当作 fuzz 引擎或长时资源保障。消费者 fixture 输出 `Public API smoke passed: 6 checks`。`NumericContractTests` 内有 512 次 Int8 + 512 次 UInt8 有限域解码、60 种边界/表示/策略组合及补充的小数与极长指数用例；这些循环不是独立的 XCTest 方法。消费者 fixture 仅 `import SmartCodable`；encode-only 模型需显式实现 `SmartEncodable` 的三个协议要求，宏继承不在本 fixture 的覆盖范围。

## 数值失败与主进程保护

```sh
swift test --filter NumericSubprocessTests
```

父用例分别启动子进程，传入模型 ID、策略、原样十进制输入或 JSON Data。每个子进程 5 秒超时，stdout/stderr 单独落入临时文件；父进程记录退出种类、状态、输出及失败输入。2026-11-02 修复前，主 XCTest 进程没有被 Swift trap 杀死，**总计 2 条 XCTest（子入口跳过 1 条），父用例有 3 条断言失败，命令退出 1**：

```text
model: SubprocessInt64, declared default: 77
input: "-9223372036854775809" (decimal string)
policies: strict, truncate, rounded
expected: 77
observed: -9223372036854775808
child exit: 0 (wrong result, not a crash)
```

上溢的 Int64 `9223372036854775808`、UInt64 `18446744073709551616` 和有效端点在同一父用例中执行且未触发 trap。2026-11-03 修复后，原始下溢及补充的小数、指数边界在子进程中全部通过；Debug/Release 全量测试各 142 条、1 条子入口跳过、0 失败，`swift test --enable-code-coverage` 也退出 0。无需在生产进程调用 `try?` 伪装 Swift trap 为业务错误。

## 独立属性测试与 seed

```sh
swift test --package-path Tools/PropertyTests
```

固定依赖 PropertyBased 2.0.1，要求该独立包的 Swift tools 6.1；本机 Swift 6.4 下实际执行 7 项性质。单次通过运行的随机序列不固定；若失败，PropertyBased 输出原始和缩减后的具体输入以及 `.fixedSeed(...)`。**仅在重放失败时**把 seed 添加到相应 `@Test`，再运行同一过滤器；该库会在固定 seed 没有再复现失败时记录问题，这是有意的校准行为。

本轮人工失败校准的原始输入 `317` 缩成 `1`；固定种子数值形式为：

```swift
@Test(.fixedSeed(3492100703560300995, 5906534046504934986,
                 13873651063326308440, 3156236000285152078))
```

临时校准性质为 `Gen.int(in: 1...1000)`、`#expect(n < 1)`，两次运行都报告相同原始与缩减值。失败性质没有保留在公开测试包；私有原始/重放日志由维护者保存。可重复成功运行需使用根包 `Tests/StructuredSemanticTests.swift` 的 `lcg-v1`、固定 seed `0xBADA_55C0_FFEE_0001`。失败消息包含迭代号、状态、原始字节和具体 payload；它并不依赖只保存 seed。

## 并发诊断与环境界限

```sh
swift test --sanitize=thread --filter GlobalOptionsConcurrencyTests
swift test --sanitize=thread --filter DecodingContextTests.testConcurrentIndependentDecodersFallbackDefaultsStayIsolated
swift run --package-path Tools/Diagnostics --sanitize=thread SharedDecoderProbe
```

本机两项过滤器分别执行 2 与 1 条 XCTest，均无 TSan 报告；第三项单独诊断同一个 decoder 64 次并行调用，输出 `mismatches=0`，一次阴性结果不能证明并发契约。独立诊断包首次冷构建实测约 1701.76 秒，因此没有加入 PR gate。手工检查过滤器执行数必须大于零；SwiftPM 过滤器匹配零项仍可能退出 0。

```sh
swift test --sanitize=address --filter NumericContractTests
swift test --enable-code-coverage
```

ASan 数值过滤器在本机执行 6 条且通过。2026-11-02 的覆盖率运行因下溢失败退出 1，当时需手动合并 `.profraw`；修复后全量覆盖率运行退出 0，生成 `default.profdata`。2026-11-03 已安装 LLVM 23.1.4 与 iOS 27.0 模拟器，现有两个**本地 Swift libFuzzer** 目标可运行：

```sh
./Fuzzing/run.sh raw 32
./Fuzzing/run.sh structured 32
```

两条命令分别退出 0；源码插桩加载逾万计数器，有效 seed 进入模型。具体工具链要求、语料与重放规则见 `Fuzzing/README.md`。此链接采用 Homebrew clang 驱动，**没有开启 ASan 或 TSan**；不要以 32 次短跑证明深度资源或内存安全。

本机检查安装状态：

```sh
/opt/homebrew/opt/llvm/bin/clang --version
muter --version
xcrun simctl list runtimes
xcrun simctl list devices available
```

本机 `muter --version` 为 16，隔离小包上 1 个关系运算符 mutant 被杀死；SmartCodable 测试曾因 F-01 失败，现已修复；可在隔离工作树尝试 Muter，不能把小包结果当作本仓库变异分数。保留的 `SmartCodable-Test` 设备在验证启动后已关闭，需要时可用 `simctl boot` 启动。iOS 27.0 模拟器目标构建已通过：

```sh
swift build --triple arm64-apple-ios27.0-simulator \
  --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  --package-path .
```

此命令仅编译目标。2026-11-03 另在仓库外通过 XcodeGen 生成采用 UIScene 生命周期的临时 iOS 测试宿主，以 Xcodebuild 在 iOS 27 的 `SmartCodable-Test` 设备上实际执行 **140 条 XCTest，0 失败**；`NumericSubprocessTests` 的 macOS 专属 2 条不参与 iOS 测试。测试宿主和结果 bundle 保存在仓库外临时目录，未加入公共 CI；不宣称已验证最低 iOS 13。
