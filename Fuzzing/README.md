# SmartCodable 覆盖引导 Fuzzing

两个独立目标分别检查原始 Data 的崩溃或挂起，以及有界结构化输入的解码语义。根包不依赖 fuzzing 工具；以下脚本在 macOS 上使用 Xcode 命令行工具和 Homebrew LLVM 构建。

从仓库根目录运行：

```sh
brew install llvm
export SMART_FUZZ_SCRATCH="$PWD/.build/fuzz"
./Fuzzing/run.sh raw 32
./Fuzzing/run.sh structured 32
```

脚本将默认种子复制到 scratch 路径；探索语料和崩溃文件不会写回种子目录。也可以不设置 `SMART_FUZZ_SCRATCH`，让脚本使用系统临时目录。`runs` 必须是正整数；RawInput 最大 512 字节，StructuredSemantic 最大 64 字节，每个输入超时为 2 秒。

脚本通过 Swift 的 `-sanitize=undefined -sanitize-coverage=edge,inline-8bit-counters,pc-table` 编译 SmartCodable 和 Swift harness，再由 Homebrew LLVM 的 `clang++ -fsanitize=fuzzer` 链接主程序。此组合不提供 ASan 或 TSan 保障；需要时应单独运行这些检查。工具链变更后先验证构建、链接和目标可达性。

- `raw`：有限字节进入公开的 `deserialize(from: Data)`。非法 JSON 可以正常被拒绝；异常退出或 libFuzzer 超时需要调查。
- `structured`：前三字节确定性地产生 Int16 以及 number/string/missing/invalid 状态之一。预期值来自输入字节和模型声明默认值，不调用 SmartCodable 的数值转换；不匹配时触发 `fatalError`。

默认种子位于 `Fuzzing/Corpus/Seeds/`。发生失败后，可用生成的二进制重放单个 crash 文件，例如将下列路径替换为实际文件：

```sh
"$SMART_FUZZ_SCRATCH/bin/structured" -runs=1 "$SMART_FUZZ_SCRATCH/artifacts/structured/crash-<hash>"
```

记录目标、输入和工具链，以便重放；确认后的回归应与自动生成的探索语料分开管理。短跑、固定种子和覆盖计数都不能证明任意输入或长期运行安全，也不能代替根包数值边界回归和单独的 sanitizer 测试。
