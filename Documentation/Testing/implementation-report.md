# SmartCodable 自动化测试增量实施报告

日期：2026-11-02。仓库 `SmartCodable`，分支 `7.0.2`，HEAD `bc1522f6b635128ea992331867fe65f231492dc0`，与研究报告的提交基线相同。**测试对象是包含本地未提交修复的工作区，不是仅 HEAD 的源码**：此前修复已将整数浮点中转改为 `T(exactly:)`、扩充 Sentinel 和编码/解码回归。本轮保留这些用户修改，没有重置、stash、提交或推送。配套仓库 `SmartCodableMacro` 为 `main`/`ce1bdd683a4b472efed9681ace0d727fe1586188`。

## 环境与边界

- Apple Swift 6.4（swiftlang-6.4.0.34.1）、Xcode 27.0（27A266a）、macOS 26.6.2、arm64、macOS SDK 27.0；`simctl list devices available` 未列出可用 iPhone/iPad。仅本机 macOS 执行，iOS 等部署平台未验证。
- 根 `Package.swift` 仍是 Swift tools 5.9、iOS 13 起，零外部依赖；独立 `Tools/PropertyTests` 使用 tools 6.1 和精确 PropertyBased 2.0.1（revision `7d405e77a7b729390ed1d9a66e1f80a707fd03c4`）。根包工具链与公开 API 未改动。
- 本轮只编辑 `.github/workflows/swift.yml`、`Tests/TestSupport.swift`，新增 5 个根 XCTest 文件、3 个测试专用独立包（公开消费者、PropertyBased、并发诊断）与 `Documentation/Testing/` 文档。构建日志、临时探针和变异工作树均位于仓库之外，没有纳入公开交付。

## 实际执行结果

| 阶段/命令 | 实际结果 | 状态 |
| --- | --- | --- |
| 起始 `swift build` / `swift test` | build exit 0；121 条 XCTest、0 失败，test exit 0 | 已验证基线（含此前未提交代码） |
| 起始 `swift build -c release` / `swift test -c release` | 0 / 0；Release 121 条、0 失败 | 已验证基线 |
| 起始 `swift test --enable-code-coverage` | exit 0；121 条、0 失败；生成 profile 并导出报告 | 已验证基线 |
| `swift test --filter NumericContractTests` | 6 条、0 失败；Int8/UInt8 1024 次有限域解码，加 60 种策略/表示/边界组合 | 已验证 |
| `swift test --filter JSONOracleTests` | 首次 7 条中 2 条因原比较器 Bool/数字混淆失败；修正**仅测试支持**后 7 条、0 失败 | 已复现并修正测试预言机 |
| `swift test --filter StructuredSemanticTests` | 3 条、0 失败；固定 `lcg-v1` seed，500 次字段状态 + 两组各 160 次组合 | 已验证 |
| `swift test --filter RawInputSmokeTests` | 1 条、0 失败；512 个短字节输入和一份可达模型的合法 JSON seed | 仅有界语法/崩溃烟测，不是 fuzzing |
| `swift test --filter NumericSubprocessTests` | 上溢及合法端点通过；新增下溢 3 种策略输出错误 `Int64.min`；2 条 XCTest，1 条子入口跳过，3 条失败，exit 1 | 已复现生产 bug，未越权修改生产代码 |
| `swift run --package-path Tools/PublicAPISmoke PublicAPISmoke` | exit 0；仅公开导入，6 条消费者检查通过 | 已验证 |
| `swift test --package-path Tools/PropertyTests` | exit 0；7 项 Swift Testing 性质通过；XCTest 计数为 0 是独立框架格式，不是过滤器漏跑 | 已验证本机集成 |
| 人为失败 shrink 校准及固定 seed 重放 | 两次均 exit 1（预期）；原始输入 317 缩至 1，固定数值 seed 重放同一反例 | 已验证；故意失败文件已从公开包移除 |
| 两项定向 `swift test --sanitize=thread --filter ...` | 全局选项 2 条、独立 decoder 1 条，均 0 失败且无 TSan 警告 | 已验证非零匹配 |
| `swift test --sanitize=address --filter NumericContractTests` | 6 条、0 失败 | 已验证本机 ASan |
| `swift run --package-path Tools/Diagnostics --sanitize=thread SharedDecoderProbe` | exit 0；64 次同实例解码，mismatches=0，无 TSan 报告；首次独立包冷构建耗时约 1701.76 秒 | 诊断阴性，契约未确认；不纳入 PR gate |
| 最终 Debug 构建与 `swift test` | build exit 0；**140 条、1 跳过、3 失败，test exit 1** | 已确认 Int64 下溢造成失败 |
| 最终 Release 构建与 `swift test -c release` | build exit 0；**140 条、1 跳过、3 失败，test exit 1** | 同一已确认失败 |
| 新增后 `swift test --enable-code-coverage` | exit 1；140 条、1 跳过、3 失败；`.profraw` 手工合并后可读取报告 | 覆盖率数据含失败运行 |
| 独立 Release 性能趋势 | 单次 n/2n/4n 每档 3 次，中位数 2.816 / 5.158 / 9.833 ms；无峰值内存 | 仅趋势，不作为门禁 |
| 2 个隔离工作树人工变异 | 对照先非零通过；修改后均编译，目标测试失败；临时 worktree 已删除 | 2 killed，非全库分数 |

## 文件与 CI 范围

- `Tests/NumericContractTests.swift`：全域、边界与 Bool 有效/非法域；`Tests/NumericSubprocessTests.swift`：独立子进程、信号与 5 秒超时；`Tests/JSONOracleTests.swift`：独立 JSON 类型标签与比较器校准；`Tests/StructuredSemanticTests.swift`：确定性有界语义输入；`Tests/RawInputSmokeTests.swift`：512 个有界原始字节与有效 seed。`Tests/TestSupport.swift` 只修复比较器，未修改生产模块。
- `Tools/PublicAPISmoke/`：公开 API 消费者编译与六项断言；`Tools/PropertyTests/`：精确锁定的独立依赖与七项性质；`Tools/Diagnostics/`：同实例并发的手工诊断程序。`.github/workflows/swift.yml` 保留 Debug/Release/两项 TSan，增加公开消费者检查、TSan 非零测试数门禁和仅 `workflow_dispatch` 执行的属性测试任务；**没有触发远端 CI**。
- `Documentation/Testing/contracts.md` 定义支持域、排除条件及独立预期；`findings.md` 区分已复现/待确认/环境阻塞；`replay-guide.md` 记录精确命令和输入；`coverage-and-mutation.md` 给出真实覆盖与变异校准。

## 未完成与成本边界

- **必须处理的产品问题**：`-9223372036854775809` 解码为 `Int64.min`，详见 `findings.md`。文档明确禁止本轮改生产行为，因此保留会失败的隔离回归；不能降断言或把它标记为预期失败以获取全绿。
- **契约待确认**：同一个 `SmartJSONDecoder` 并发使用、解码中更改全局策略的快照一致性；一次 TSan 阴性不足以证明安全。
- **环境阻塞**：本机没有可用 libFuzzer runtime，也无 iOS simulator；仅验证 Swift 覆盖插桩小探针，不创建假的 fuzz 集成。Muter 未安装，未验证兼容；人工变异替代了本轮的有限校准。只做一次固定 Release 的 n/2n/4n 延迟趋势观测，未采集峰值内存或长时性能；其它 Apple 平台和远端 CI 未验证。
- **最小下一步**：授权的生产修复任务中对整数形式先做精确范围校验，消除 Double 下溢舍入；再运行 `NumericSubprocessTests`、根 Debug/Release/TSan、独立属性测试，确认最终全绿。之后再确定 CON-02 的公开并发契约与实际 fuzz 工具链预算。

### 2026-11-03 环境处理补记

前面的基线与结果仍对应 2026-11-02。本机之后安装 LLVM 23.1.4：C libFuzzer/ASan 小探针完成 16 次运行；Apple Swift 6.4 的 `-sanitize=fuzzer` 仍不可用，直接混用 LLVM 23 与 Apple Swift ASan/libc++ 会失败。当前通过 Apple Swift 的 `-sanitize=undefined -sanitize-coverage=edge,inline-8bit-counters,pc-table` 插桩核心库及 Swift 目标，再用 Homebrew `clang++ -fsanitize=fuzzer` 链接：独立 `Fuzzing/run.sh raw 32` 和 `structured 32` 均退出 0，加载逾万计数器，种子触及模型代码。人为错误产生并重放同一份 3 字节崩溃语料；此集成**无 ASan/TSan**，仅完成本地短跑验证。Muter 16 已装入用户本地 PATH，隔离小包 1 个 mutant 被杀死，未对本仓库完整运行。Xcode 27 的 iOS 27.0 runtime 与 iPhone 18 Pro 模拟设备已安装并启动成功，验证后设备关闭；iOS 27.0 Simulator arm64 目标构建退出 0；当时尚未在模拟器执行 XCTest。安装导出镜像已清理，环境步骤未修改生产代码或触发远端 CI；细节见 `findings.md`、`Fuzzing/README.md`。

### 2026-11-03 整数下溢修复补记

根据后续明确授权，本阶段修改 `Sources/SmartCodable/Core/JSONDecoder/Patcher/Patcher+Transformer.swift`：保留目标整数的直接解析快路径，改用原始十进制数字及指数按 strict/truncate/rounded 计算候选整数，再由 `T(String)` 做最终范围判断；删除不再使用的 Double 中转函数。新增 `Tests/NumericContractTests.swift` 与 `Tests/NumericSubprocessTests.swift` 对小整数边界、Int64/UInt64 极值、相邻小数、科学计数法及极长指数的断言，未调整已有失败期望。

实际执行：Debug 与 Release 构建均退出 0；两种全量测试各执行 **142 条、1 条子进程入口跳过、0 失败、退出 0**；两项定向 TSan 分别执行 2 条和 1 条，无数据竞争报告；独立 PropertyBased 执行 7 项通过；`swift test --enable-code-coverage` 执行 142 条、1 跳过、0 失败并生成 `default.profdata`；iOS 27 Simulator arm64 目标构建通过。两项 Fuzzing 各完成 32 次短跑，公开消费者 6 项检查通过。当时未执行远端 CI，也未修改 SmartCodableMacro。本补记与前面 2026-11-02 的失败证据属于不同时间点，提交记录另行报告。

### 2026-11-03 发布前联调补记

SmartCodableMacro 临时以 `swift package edit smartcodable --path <本地 SmartCodable>` 解析到本地 `7.0.2`（SHA `064028beed52c39bb83478533ede6c4ffb9dfe9e`），Build exit 0、Macro XCTest 12 条通过；测试时 SwiftSyntax 解析到 603.0.2。完成后 `swift package unedit` 并恢复 Macro 原 `Package.resolved`（SmartCodable 7.0.0、SwiftSyntax 602.0.0）；Macro 的已跟踪文件已恢复到联调前状态。该联调证实使用本地核心库，不等于远程依赖 7.0.2 已发布。

使用仓库外临时 XcodeGen iOS 27 场景宿主，对同一核心库在 `SmartCodable-Test` iPhone 18 Pro 模拟器执行 **140 条适用 XCTest，140 通过、0 失败**。`NumericSubprocessTests.swift` 由 `#if os(macOS)` 隔离，因此 iOS 比 macOS 的 142 条少 2 条。首次私有宿主未采用 iOS 27 必需的 UIScene 生命周期，宿主启动失败；修正宿主后定向 2 条和全量 140 条通过。这是测试宿主错误，公开仓库生产代码无变化。本轮不验证最低 iOS 13。

本地 Swift workflow 已增加 `7.0.2` push 触发和该分支的 PropertyBased job；Core Debug/Release 各 142 条（1 条跳过、0 失败）、两项定向 TSan（2 条与 1 条）、独立属性测试 7 项及公开消费者 6 项均在推送前再次通过。是否已通过远端 CI 以 GitHub Actions 实际 run 结果为准；不会为此创建 PR。
