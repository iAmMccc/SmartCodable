# 覆盖与变异校准

日期：2026-11-02；本机 Apple Swift 6.4 / Xcode 27.0 / arm64 macOS 26.6.2。统计只包含 `Sources/SmartCodable/`（排除 Tests、SwiftPM 构建缓存）。工具：Apple LLVM 21.0.0 的 `llvm-cov` / `llvm-profdata`。**行与区域覆盖率不是语义正确性或分支/条件覆盖率。** 该工具的报告未提供分支覆盖数字，不能把其中的 `-` 写成 100%。

| 对象 | 增量前：121 条 XCTest 全绿 | 增量后：140 条 XCTest，1 跳过、3 失败 |
| --- | ---: | ---: |
| 源码区域覆盖 | 51.41%（2309 区域，1122 未达） | 52.58%（2309 区域，1095 未达） |
| 源码行覆盖 | 61.93%（5238 行，1994 未达） | 62.73%（5238 行，1952 未达） |
| `Patcher+Transformer.swift` 区域覆盖 | 40.00%（60 区域，36 未达） | 73.33%（60 区域，16 未达） |
| `UnkeyedContainer.swift` 区域覆盖 | 31.88%（138 区域，94 未达） | 31.88%（138 区域，94 未达） |

增量前使用 `swift test --enable-code-coverage` 生成 `default.profdata`；增量后同一命令因已复现的 Int64 下溢退出 1，SwiftPM **没有**合并 profile。手工将本次 XCTest/Swift Testing `.profraw` 通过 `llvm-profdata merge -sparse` 合并，再用同一个 XCTest 二进制和 `llvm-cov report` 生成统计。子进程数值探针的临时 profile 未纳入，不能把这些结果解释为包括所有子进程路径的覆盖率。覆盖报告只作趋势证据，不设未经测量的门禁阈值。

## 两项独立工作树变异

所有突变只在从 HEAD 创建并应用当前未提交差异的临时 worktree 运行，主工作区生产源码未改动。对照过滤器均先确认实际执行非零测试；突变编译成功、被目标断言发现。临时 worktree 已删除，原始日志保存在维护者的私有工作区。

| 变异 | 对照 | 变异结果 | 分类 |
| --- | --- | --- | --- |
| `SmartSentinel.Level.allows(.none)` 返回 `true` | `testSmartSentinelLevelAllowsPolicy` 1 条通过 | 两条 `XCTAssertFalse` 失败，测试进程退出 1 | killed |
| `_convertFloatToInteger` 将 `T(exactly: candidate)` 换为非可失败 `T(candidate)` | `NumericContractTests` 6 条通过；已知下溢单独记录 | 子进程对上溢输入触发 `Fatal error: Double value cannot be converted to Int64`；父测试观察到信号终止（该机状态 5）和失败，测试进程退出 1 | killed |

这只是 **2 个手工代表性 mutant，2 个 killed**；未运行全库 Muter，不存在可报告的全局 mutation score。现有下溢错误与第二个 mutant 导致的上溢 trap 是两种不同失败签名，未混为一谈。未观察 invalid、equivalent、survived 或 timeout 样本，不能把这些类别视为“已证实为零”。

## 覆盖盲区与下一步

`UnkeyedContainer` 区域覆盖没有增加；复杂容器/包装器的组合还需独立契约。当前数值测试精准增加了 Patcher 路径覆盖，但 Int64 下溢证明覆盖并不保证正确。`Tests/RawInputSmokeTests.swift` 与 `Tests/StructuredSemanticTests.swift` 是有界确定性保障，不能冒充覆盖引导 fuzzing。

2026-11-03 新增独立 `Fuzzing/`：RawInput 和 StructuredSemantic 两个 Swift harness 连同 **SmartCodable 本体**以覆盖计数器插桩，在 Homebrew clang libFuzzer 下各完成 32 次本地短跑；有效种子触发模型代码。人为错误校准以 3 字节输入形成 crash 文件，新进程重放相同失败签名。此结果只证明链接、覆盖可达、失败捕获与重放，未进行长时 fuzz、语料缩减、跨工具链验证或全库变异分数。当前链接方式未启用 ASan/TSan，不能替代单独的 sanitizer 测试。

## 独立 Release 趋势探针

维护者私有的 Release 探针解析相同模型的 `[Int]` 字段，预生成 JSON Data，每档运行 3 次取中位数。单机一次观察为 `n=1000: 2.816 ms`，`2n=2000: 5.158 ms`，`4n=4000: 9.833 ms`，大致随输入长度线性增长；未采集峰值内存或跨机基线，也未设置 CI 性能门禁。该探针与 sanitizer 数据不混用。

## 2026-11-03 修复后的覆盖快照

整数下溢修复后 `swift test --enable-code-coverage` 已退出 0，142 条 XCTest、1 条跳过、0 失败，正常生成 `default.profdata`。同一 `llvm-cov` 命令统计生产源码：区域 **53.48%**（2373 区域、1104 未达），行 **63.24%**（5318 行、1955 未达）；`Patcher+Transformer.swift` 区域 **79.84%**（124 区域、25 未达）。新精确十进制转换增加了源码区域及行，分母与上表不同，不将百分比差值直接解释为测试质量提升。上表两项人工变异发生于修复前工作树，其中 `_convertFloatToInteger` 已被删除；未对新实现宣称新的变异分数。
