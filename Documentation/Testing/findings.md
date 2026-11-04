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
- 与同节上一条记录时的环境不同：上一条记录时 Homebrew LLVM 23.1.4 已安装，本次 `brew info llvm` 为 Not installed。本次修改前 `./Fuzzing/run.sh raw 32`、`./Fuzzing/run.sh structured 32` 退出码 1：`Fuzzing/Sources/RawInput.swift:2:8: error: no such module 'SmartCodable'`（`StructuredSemantic.swift` 同样）。脚本写死产物目录 `$scratch/package/out/Products/Debug`，当前 SwiftPM 的 `swift build --show-bin-path` 给出 `…/package/arm64-apple-macosx/debug`，模块在其 `Modules/SmartCodable.swiftmodule`，且不生成 `libSmartCodable.a`。`Fuzzing/run.sh` 已改为用 `swift build --show-bin-path` 定位产物目录，模块目录取 `Modules/` 或产物根目录，链接输入为 `libSmartCodable.a`，否则 `SmartCodable.build/*.o`；`bash -n Fuzzing/run.sh` 通过。修改后两条命令仍退出码 1：`./Fuzzing/run.sh: line 70: /opt/homebrew/opt/llvm/bin/clang++: No such file or directory`。`brew info llvm` 为 Not installed；Xcode clang 工具链没有 `libclang_rt.fuzzer*`。因此链接、libFuzzer 短跑与 `-runs=1` 单输入重放本次均未执行，**状态为环境阻塞，未验证**。
- 官方 Muter 16 校验下载归档的 SHA-256 后在隔离目录构建：整个 `swift build -c release` 因旧测试目标无法解析 `muterCore` 退出 1，但已生成的可执行程序可用。程序安装到用户本地 PATH；`muter --version` 为 16。独立 Swift 5.9 小包实测 1 个关系运算符 mutant、1 个 killed，报告注明跳过覆盖筛选。**仅说明此最小样例可运行**；当时 SmartCodable 根包尚未全绿，现 F-01 修复后仍未在本仓库跑全库 Muter。
- Xcode 27 的 iOS 27.0 runtime（24A434）已下载并安装。`SmartCodable-Test` iPhone 18 Pro 模拟设备已成功启动，验证后关闭；导出镜像已清理。以 iOS 27.0 Simulator SDK 和 arm64 simulator triple 编译 SmartCodable 成功；随后在仓库外生成临时 XCTest 宿主，iOS 27 模拟器实际运行 **140 条测试，0 失败**。未验证最低 iOS 13 部署版本（本轮不要求）。磁盘余量以当次 `df -h` 为准。
- 同实例 decoder 的公开并发契约仍需项目确认；软件安装不会替代语义定义和带日志归属断言的并发测试。
- 2026-11-04：`brew install llvm` 安装 Homebrew LLVM 23.1.4（含 `libclang_rt.fuzzer_osx.a`）。`./Fuzzing/run.sh raw 32` 与 `structured 32` 退出 0（`Done 32 runs`，raw cov 339、structured cov 378）。默认种子 `-runs=1` 重放退出 0。校准：副本中把比较改为 `expected &+ 1`，种子 `[97, 98, 97]` 触发 fatalError（退出 77），新进程 `-runs=1` 重放同一签名（退出 77）。`Fuzzing/run.sh` 用 `swift build --show-bin-path` 定位产物后链接成功。32 次短跑不代表长期稳定性，仍不含 ASan/TSan。

## F-06：非可选模型数组中 null 或非对象元素使整个属性回退声明默认值

**状态：已复现；按补丁版本稳定性维持现有实现，contracts.md ARR-01 已改为如实描述该行为并指向 `@SmartCompact.Array`；本轮未修改生产代码。** origin/7.0.1 行为相同，不是 7.0.2 回归。依据：origin/7.0.1 同一文件第 177-178 行注释原文为 “If it is not the first level of array model parsing, it is not compatible. Throw an exception to make keyedController compatible.”，引入提交 `8136261`（2024-05-28「处理Unkey容器的兼容逻辑」）中的原文为「如果不是第一层级的数组模型的解析，就不兼容。抛出异常让keyedController兼容。」`README.md:233` 与 `README_CN.md:232` 推荐 `@SmartCompact.Array` 跳过无效元素。

- 模型：`struct Child: SmartCodableX { var id = -1 }`，`didFinishMapping` 中 `id += 10`；`var ordinary: [Child] = []`。输入 `{"ordinary": [{"id":1}, null, {"id":2}]}`。实际 `[]`。非对象元素 `"bad"` 同样得到 `[]`。
- 对照：中间元素为 `{}` 时得到逐元素 `[11, 9, 12]`；`[[Int]]` 的 null 元素逐元素回退为 `[]`；`[Int]` 的 null 元素回退为 0（`Tests/AuditRegressionTests.swift` 的 `testNestedArrayKeepsElementAlignment` 得到 `[1, 0, 3]`）。
- 触发链：`KeyedContainer._decodeDecodable`（`Sources/SmartCodable/Core/JSONDecoder/Decoder/Impl/JSONDecoderImpl+KeyedContainer.swift` 第 434-442、501-509 行）进入 `Array.init(from:)` 逐元素解码。`UnkeyedContainer.decode`（`JSONDecoderImpl+UnkeyedContainer.swift` 第 158-178 行）失败后调用 `forceDecode`（第 206-229 行）。null 元素在 `JSONDecoderImpl.swift` 第 85-89 行抛出 "Cannot get keyed decoding container -- found null value instead"。错误冒出 `Array.init`，属性级 `try?` 失败，整个属性使用声明默认值 `[]`。
- origin/7.0.1 的 `JSONDecoderImpl+UnkeyedContainer.swift` 第 169-182 行在 `codingPath` 非空时直接 `try unwrap`（第 179 行），不进入 `forceDecode`。属性同样回退为 `[]`。属既有问题。
- `Tests/Branch702ReviewRegressionTests.swift` 的 `testR2CallbacksAndOrdinaryArray` 现有断言把 null 输入的 `ordinary` 固定为 `[]`；`{}` 元素的断言为 `[11, 9, 12]`。
- 重放：`swift test --filter Branch702ReviewRegressionTests/testR2CallbacksAndOrdinaryArray`。

## F-07：macOS 上 @SmartHexColor 编码改变颜色分量

**状态：已修复（2026-11-04）。** 修复前只在 macOS 复现：ExampleApp 在 iPhone 17（iOS 26.5）模拟器上，页面「重命名键的默认值与包装器」对同一输入显示实际 `#FF0000`、判定一致。页面源码 `Example/ExampleApp/ExampleApp/01_Basic/DefaultValueKeyMappingDemoViewController.swift`。

- 输入 `["color_value": "FF0000"]`，`encodeHexFormat: .rrggbb(.hash)`，并使用重命名 `CodingKeys` 与 `SmartDefaultValueKeyMapping`。期望 "#FF0000"。修复前 macOS 实际 "#FF2600"。12 种格式修复前为 `#f20`、`0xf20`、`f20`、`#ff2600`、`0xff2600`、`ff2600`、`#f20f`、`0xf20f`、`f20f`、`#ff2600ff`、`0xff2600ff`、`ff2600ff`，绿色通道为 0x26。
- 修复前触发链：`Sources/SmartCodable/Core/PropertyWrapper/SmartHexColor.swift` 解码第 166 行 `NSColor(calibratedRed:green:blue:alpha:)`。编码读分量曾用 `usingColorSpace(.deviceRGB)`，分量转整数为截断 `Int(value * 255)`。
- 修复：解码仍为 `NSColor(calibratedRed:green:blue:alpha:)`（`Sources/SmartCodable/Core/PropertyWrapper/SmartHexColor.swift` 第 166 行），解码出的颜色对象不变。macOS `rgbaComponents`（第 314-321 行）：颜色为 component-based 且 `colorSpace == .genericRGB` 时直接读分量（第 317-318 行）；其他颜色仍按 7.0.1 `usingColorSpace(.deviceRGB)` 后读分量（第 320-321 行）。分量转整数四舍五入 `Int((value * 255).rounded())`（第 187-188 行），iOS 与 macOS 共用。
- `.rrggbb(.hash)` 测量，7.0.1 写法 / 最终写法：`srgbRed:1,0,0` `#FF0000`/`#FF0000`；`deviceRed:1,0,0` `#FF0000`/`#FF0000`；`calibratedRed:1,0,0` `#FF2600`/`#FF0000`；`NSColor.red` `#FF0000`/`#FF0000`；`systemRed` `#FF383C`/`#FF383C`；`displayP3Red:1,0,0` `#FF0000`/`#FF0000`；sRGB `0x12/0xAB/0x34` `#12AB34`/`#12AB34`。只有 generic/calibrated RGB 颜色的结果改变。曾评估的「统一转 genericRGB」会使 sRGB 纯红变 `#FB0007`，已放弃。
- 测试：`Tests/DecodingContextTests.swift` 的 `testSmartHexColorKeepsDeclaredEncodeFormatAcrossRoundTrip` 仍通过。`testR4RenamedColorDeclaration` 精确 "#FF0000"。`testR11HexColorFormatsRestoredForRenamedKey` 12 格精确为 "#F00"、"0xF00"、"F00"、"#FF0000"、"0xFF0000"、"FF0000"、"#F00F"、"0xF00F"、"F00F"、"#FF0000FF"、"0xFF0000FF"、"FF0000FF"。`testR18HexColorChannelRoundTrip`：`.rrggbbaa(.none)` 1024 次、`.rgba(.none)` 64 次。`testR19HexColorEncodesCodeCreatedColors`（macOS）sRGB/device/calibrated 纯红 → "#FF0000"，sRGB `0x12/0xAB/0x34` → "#12AB34"。修复前 R4 得 "#FF2600"、R11 12 条失败、R18 1088 条全部失败（首条 "00919280" ≠ "00808080"）。
- 重放：`swift test --filter Branch702ReviewRegressionTests/testR4RenamedColorDeclaration`；`swift test --filter Branch702ReviewRegressionTests/testR11HexColorFormatsRestoredForRenamedKey`；`swift test --filter Branch702ReviewRegressionTests/testR18HexColorChannelRoundTrip`；`swift test --filter Branch702ReviewRegressionTests/testR19HexColorEncodesCodeCreatedColors`。

## F-09：[Model?] 数组元素不执行 didFinishMapping

**状态：已修复（2026-11-04）。** 修复前 origin/7.0.1 已存在，不是当时的 7.0.2 回归。

- 输入：`struct Child: SmartCodableX { var id = -1; var calls = 0; didFinishMapping 中 calls += 1、id += 10 }`，`var optional: [Child?] = []`，`{"optional": [{"id":1}, null, {"id":2}]}`。期望非 nil 元素 id 为 11、12（各回调 1 次）。修复前实际 `[1, nil, 2]`，calls `[0, nil, 0]`。非对象元素 `"bad"` 修复前同样得到 `[1, nil, 2]`。
- 对照：`var child: Child?`、`[String: Child?]` 的值、`var children: [Child]?` 的元素都执行回调，id 为 11。
- 修复前触发链：`didFinishMapping<T>` 中 `guard T.self is SmartDecodable.Type else { return decodeValue }`，`T` 为 `Optional<Child>` 时直接返回。origin/7.0.1 同文件第 371-374 行相同。
- 修复：`Sources/SmartCodable/Core/JSONDecoder/Decoder/Impl/JSONDecoderImpl+UnkeyedContainer.swift` 第 366-388 行对 `Optional<SmartDecodable>` 元素解包（第 397-403 行 `mappedElement`）。非 nil 元素回调一次，nil 保持 nil。与 keyed 容器 `decodeIfPresent` 后回调一致（`JSONDecoderImpl+KeyedContainer.swift` 第 423-431 行）。
- 测试：`Tests/Branch702ReviewRegressionTests.swift` 的 `testR17OptionalModelArrayKeepsElementPositions`。null 与 "bad" 两组 ids `[11, nil, 12]`、calls `[1, nil, 1]`；`[[Child?]]` → `[[11, nil]]`；无回调 `[Plain?]` 两组 `[1, nil, 2]`。修复前 ids `[1, nil, 2]`、calls `[0, nil, 0]`。
- 重放：`swift test --filter Branch702ReviewRegressionTests/testR17OptionalModelArrayKeepsElementPositions`。

