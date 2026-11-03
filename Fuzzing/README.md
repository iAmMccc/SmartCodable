# SmartCodable 本地覆盖引导 Fuzzing

两个独立目标分别检查原始 Data 的崩溃/挂起与有界语义。根 `Package.swift` 和 Swift 5.9 最低要求不变；Fuzzing 只通过独立脚本在 macOS 上构建。当前验证环境为 Xcode 27 / Apple Swift 6.4 / Homebrew LLVM 23.1.4（arm64）。

```sh
brew install llvm
./Fuzzing/run.sh raw 32
./Fuzzing/run.sh structured 32
```

脚本将有效种子复制到 scratch 路径，之后运行期间生成的探索语料与崩溃文件**不会写回仓库**。默认使用系统临时目录；可设 `SMART_FUZZ_SCRATCH` 显式指定持久目录。`runs` 必须是正整数；RawInput 最大 512 字节，StructuredSemantic 最大 64 字节，每个输入 2 秒超时。

Apple Swift 在本机对 macOS arm64 不支持 `-sanitize=fuzzer`。脚本使用 Swift 可用的 `-sanitize=undefined -sanitize-coverage=edge,inline-8bit-counters,pc-table` 编译 **SmartCodable 本体与 Swift harness**，再以同一 Homebrew LLVM 的 `clang++ -fsanitize=fuzzer` 链接主程序。这是可运行的覆盖引导目标，**没有** ASan/TSan 内存或数据竞争保障；这两项须在各自独立测试作业运行。不能把仅有 harness 插桩当作覆盖库源码。

- `raw`：任意有限字节进入公开 `deserialize(from: Data)`。非法 JSON 正常被拒绝，不判失败；异常退出、libFuzzer 超时才是信号。
- `structured`：前三字节确定性产生 Int16、number/string/missing/invalid 之一；期望来自原始字节和模型声明默认值，不使用 SmartCodable 的数值转换算期望。失败执行 `fatalError`，输入字节由 libFuzzer 保存，可独立重放。

运行日志必须出现 SmartCodable 源码的覆盖信息或 `NEW_FUNC`，且有效 JSON 种子必须触及模型初始化。失败后直接用生成的二进制重放单个文件，例如：

```sh
export SMART_FUZZ_SCRATCH="${TMPDIR:-/tmp}/smartcodable-fuzzing-$(id -u)"
"$SMART_FUZZ_SCRATCH/bin/structured" -runs=1 "$SMART_FUZZ_SCRATCH/artifacts/structured/crash-<hash>"
```

默认 seed 在 `Fuzzing/Corpus/Seeds/`；探索语料和确认后的回归分开保存。不要直接把随机生成的全部语料提交到 Git。工具链、C++ runtime 或 sanitizer 版本改变后，先以短 `-runs=32` 验证链接、运行、模型路径可达，再增加时间预算。根包的独立子进程测试曾发现 Int64 下溢错误；2026-11-03 已修复并保留断言，Fuzzing 目标不替代这条回归。
