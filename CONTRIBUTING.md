# Contributing to SmartCodable

感谢你对 SmartCodable 的关注！我们欢迎各种形式的贡献：Bug 报告、功能建议、文档改进、代码贡献。

## 开始之前

1. 阅读 [README](README.md) 了解项目功能
2. 阅读 [TechnicalGuide](Document/TechnicalGuide.md) 了解项目架构和设计意图
3. 检查 [Issues](https://github.com/iAmMccc/SmartCodable/issues) 确认你的问题/想法是否已被讨论

## 报告 Bug

使用 [Bug Report 模板](https://github.com/iAmMccc/SmartCodable/issues/new?template=bug_report.md) 提交，请包含：

- SmartCodable 版本、Swift 版本、Xcode 版本
- 最小可复现代码（JSON 数据 + Model 定义 + 调用代码）
- 期望结果 vs 实际结果
- 如果可能，附上 `SmartSentinel.debugMode = .verbose` 的日志输出

## 功能建议

使用 [Feature Request 模板](https://github.com/iAmMccc/SmartCodable/issues/new?template=feature_request.md) 提交，请说明：

- 你想解决什么问题
- 你期望的 API 是什么样的
- 是否有替代方案

## 提交代码

### 环境准备

```bash
git clone https://github.com/iAmMccc/SmartCodable.git
cd SmartCodable
swift build
```

- 最低要求：Swift 5.0、Xcode 14
- 宏相关功能需要：Swift 5.9、Xcode 15

### 开发流程

1. 从 `main` 分支创建你的功能分支：`git checkout -b feature/your-feature`
2. 进行修改
3. 确保 `swift build` 通过
4. 提交 PR，描述你的改动内容和原因

### 代码规范

- **不破坏公共 API**：`SmartDecodable`、`SmartEncodable`、属性包装器的公开接口不能改签名
- **向后兼容**：保持 Swift 5.0+ / iOS 13+ 的最低版本要求
- **不新增 SwiftSyntax 依赖**：核心模块（`SmartCodable` target）不能依赖 SwiftSyntax
- **DecodingCache 快照必须成对调用**：`cacheSnapshot()` 和 `removeSnapshot()` 必须配对，注意异常路径
- 修改核心解码逻辑后，至少手动验证：简单模型、嵌套模型、数组模型、类型不匹配、缺失字段

### Commit 规范

```
<type>: <简短描述>

<详细说明（可选）>
```

type 取值：
- `fix`: Bug 修复
- `feat`: 新功能
- `docs`: 文档
- `refactor`: 重构（不改变功能）
- `test`: 测试
- `chore`: 构建/CI/工具链

示例：
```
fix: 修复 UnkeyedContainer 解码 String 时 currentIndex 被递增两次

decodeIfPresent(String) 方法开头多了一次 currentIndex += 1，
导致数组解析时跳过元素。与 decodeIfPresent(Bool) 对比确认为遗漏。
```

### PR 说明

- PR 标题简洁，正文说明改了什么、为什么改
- 一个 PR 只做一件事，避免混合不同类型的改动
- 如果是较大的功能，建议先开 Issue 讨论方案

## 标记为 `good first issue` 的任务

如果你是第一次贡献，可以从标记为 [`good first issue`](https://github.com/iAmMccc/SmartCodable/labels/good%20first%20issue) 的任务开始。这些任务通常是：

- 补充单元测试
- 改善文档和示例
- 修复已确认的小 Bug

## 捐赠支持

如果你想通过捐赠支持项目，请查看 [捐赠页面](Explore%26Contribute/Contributing.md)。

## 社区

- [GitHub Discussions](https://github.com/iAmMccc/SmartCodable/discussions) — 提问与讨论
- QQ 交流群：865036731
