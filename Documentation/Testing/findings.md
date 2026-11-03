# 测试发现与证据状态

审查基线 `bc1522f6b635128ea992331867fe65f231492dc0`；验证对象为 `7.0.2` 上包含先前未提交修复的工作区。日期：2026-11-02。**本轮只修改测试、测试支持代码、独立测试包、工作流和正式测试文档，不修改生产源码或公开 API。**

## F-01：Int64 下溢被错误解成 Int64.min

**状态：已复现；2026-11-03 已修复，根包 Debug/Release 各 142 条测试通过（1 条子进程入口跳过）。**

- 模型：`SubprocessInt64`，`value: Int64 = 77`；输入十进制字符串 `-9223372036854775809`，数学上比 `Int64.min` 小 1。
- strict / truncate / rounded 三种策略分别在独立 XCTest 子进程运行；子进程均正常退出（exit 0），但输出 `observed=-9223372036854775808`，预期回退声明默认值 `77`。父测试记录 3 条失败，未把错误吞掉。
- 触发链：`_fixedWidthInteger` 的精确整数解析失败后使用 `Double`；该输入舍入为可表示的 `Int64.min`，`T(exactly:)` 对舍入后的 Double 成功，丢掉原始整数超界信息。修复应在浮点中转**之前**检查整数形式的精确十进制范围；不能再用 Double 检验该边界。生产代码在 `Sources/SmartCodable/Core/JSONDecoder/Patcher/Patcher+Transformer.swift`；重现程序在 `Tests/NumericSubprocessTests.swift`。
- 对照：`9223372036854775808`、`18446744073709551616` 的上溢在三种策略下都回退默认值且无 trap；有效的 Int64/UInt64 端点均保留原值。这与研究报告 F-01 的“上界 trap 候选”不同：上界先前已修复，下界在本次修复前仍有真实语义错误。
- 修复：`_fixedWidthInteger` 保留可解析整数的快路径；小数和科学计数法以原始十进制数字及 exponent 确定 strict/truncate/rounded 的整数结果，最后用 `T(String)` 检查范围，不经过有损 `Double`。已覆盖合法上下边界及相邻小数、极长 exponent 和超过 Decimal 精度的小数。重放：`swift test --filter NumericSubprocessTests`；完整命令见 `replay-guide.md`。

## F-02：TestSupport.deepEqual 把 Bool 与数字视为相等

**状态：已复现，已在测试支持代码中修正并用自测校准。** 原比较器先执行 `as Int`/`as Double`，Foundation `NSNumber(true)` 与 `NSNumber(1)`、`false` 与 `0` 均被判为相等；校准测试先出现 2 条失败。现改为先检查 CFBoolean 类型标签，再用 Decimal 比较有限数字。`Tests/JSONOracleTests.swift` 的七组比较检查通过；对象键顺序不影响结果、数组顺序与缺字段/null 有别，大整数不经 Double，`NaN` 被排除在合法 JSON 域外，整数数学域按 `-0 == 0`。受影响的旧 `deepEqual` 只在 EncodeTests 的两处输出比较中调用；本轮未触碰生产转换代码。

## F-03：同一 SmartJSONDecoder 的并发契约

**状态：契约待确认；一次诊断没有观察到数据竞争或错值。** `Tools/Diagnostics` 用一个 decoder 做 64 次并行解码，TSan 插桩版核心库参与链接，输出 `mismatches=0`，无 TSan 警告；这不是同实例长期并发安全保证。`SmartJSONDecoder` 声明 `@unchecked Sendable`，而 `smartDecode` 仍向实例 `userInfo` 写 `parsingMark`。尚未确定同时修改策略、日志归属和同实例并发的公开语义。不得因这次阴性结果擅自改同步行为。现有两项独立实例/全局选项定向 TSan 均非零执行且通过。

## F-04：高级测试工具本地状态

- **已验证**：PropertyBased `2.0.1` 的独立包在本机 Swift 6.4 编译运行，7 项性质通过；固定版本见 `Tools/PropertyTests/Package.resolved`。故意失败性质从 `317` 缩减到 `1`，用记录的数值 seed 重放时得同一反例。该校准只在私有临时测试文件运行，未保留故意失败测试在公开包。该库的 `.fixedSeed` 是**失败重放模式**，不用于正常通过的测试，否则会报告“fixed seed was used, but no expectation failure occured”。
- **环境阻塞**：本机 `swiftc -sanitize=fuzzer` 对 arm64 macOS 报 unsupported option；Clang 的 `-fsanitize=fuzzer` 缺少 `libclang_rt.fuzzer_osx.a`。Swift `-sanitize=address -sanitize-coverage=edge` 的小探针可编译运行，但不能据此声称 libFuzzer 引擎或 SmartCodable 覆盖引导已接入。未新增空壳 Fuzzing target。
- **未验证**：Muter 本机未安装，tag 16 与当前 Swift 工具链的兼容性未验；不把未安装说成不兼容。iOS simulator 无可用设备，没有执行 iOS 运行验证。

## F-05：覆盖率数据的限制

2026-11-02 新增测试后的根包全量测试曾因 F-01 失败，`swift test --enable-code-coverage` 退出 1，SwiftPM 未生成合并后的 `default.profdata`；当时使用 `.profraw` 手工合并。2026-11-03 修复后同一命令退出 0，142 条 XCTest、1 条跳过、0 失败，正常生成 `default.profdata`。两个时间点的数字不能混写为一次全绿运行；见 `coverage-and-mutation.md`。

## 2026-11-03 本机环境复核

以下结果更新 F-04 的**当前环境状态**，不改写 2026-11-02 的历史执行记录：

- Homebrew LLVM 23.1.4 已安装，`libclang_rt.fuzzer_osx.a` 存在；最小 **C** libFuzzer/ASan 目标完成 16 次运行。Apple Swift 6.4 对 macOS arm64 仍拒绝 `swiftc -sanitize=fuzzer`。直接在 Apple Swift 链接 LLVM 23 Fuzzer/ASan 会因 libc++/sanitizer ABI 冲突失败；改用 Swift 支持的 `-sanitize=undefined -sanitize-coverage=edge,inline-8bit-counters,pc-table` 插桩**核心库和两个 Swift harness**，以同一 Homebrew LLVM 的 `clang++ -fsanitize=fuzzer` 链接后，`Fuzzing/run.sh raw 32` 与 `structured 32` 均退出 0。运行时加载 10924/10943 个计数器，有效 seed 到达模型与解码器，证明本地覆盖引导可运行；**不含 ASan/TSan 的内存或数据竞争保障**。人为错误校准触发明确 Swift `fatalError`，生成 3 字节 crash 语料，第二进程重放同样失败签名（两次均退出 77）。当前只做 32 次短跑，不宣称长时 fuzz 或全平台兼容。
- 官方 Muter 16 校验下载归档的 SHA-256 后在隔离目录构建：整个 `swift build -c release` 因旧测试目标无法解析 `muterCore` 退出 1，但已生成的可执行程序可用。程序安装到用户本地 PATH；`muter --version` 为 16。独立 Swift 5.9 小包实测 1 个关系运算符 mutant、1 个 killed，报告注明跳过覆盖筛选。**仅说明此最小样例可运行**；当时 SmartCodable 根包尚未全绿，现 F-01 修复后仍未在本仓库跑全库 Muter。
- Xcode 27 的 iOS 27.0 runtime（24A434）已下载并安装。`SmartCodable-Test` iPhone 18 Pro 模拟设备已成功启动，验证后关闭；导出镜像已清理。以 iOS 27.0 Simulator SDK 和 arm64 simulator triple 编译 SmartCodable 成功（exit 0，5.56 秒）；尚未在模拟器执行 XCTest，也未验证 iOS 13 最低部署版本。磁盘余量以当次 `df -h` 为准。
- 同实例 decoder 的公开并发契约仍需项目确认；软件安装不会替代语义定义和带日志归属断言的并发测试。
