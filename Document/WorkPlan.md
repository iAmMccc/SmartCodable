# SmartCodable 优化工作计划

## 总览

基于对项目的全面审查，制定以下分阶段优化计划。每个 Phase 独立可交付，按优先级排序。

---

## Phase 1: 代码质量优化 - Bug 修复与拼写修正

**状态：** 已完成  
**详情：** [Phase1-BugFixes.md](Phase1-BugFixes.md)

---

## Phase 2: 代码质量优化 - 线程安全

**状态：** 已完成  
**详情：** [Phase2-ThreadSafety.md](Phase2-ThreadSafety.md)

### 目标
修复全局可变状态的线程安全问题。

### 涉及问题
| # | 问题 | 文件 | 说明 |
|---|------|------|------|
| 1 | `SmartCodableOptions` 全局可变状态无同步保护 | `SmartCodableOptions.swift` | 多线程下 `numberStrategy`、`ignoreNull` 存在数据竞争 |
| 2 | `SmartSentinel._mode` 和 `cache` 无同步保护 | `SmartSentinel.swift` | `LogCache` 是 struct 作为 static var，写操作会竞争 |
| 3 | `@unchecked Sendable` 标记不安全 | `SmartJSONEncoder.swift`、`SmartJSONDecoder.swift` | 有可变属性却声称 Sendable |
| 4 | `_iso8601Formatter` 全局共享 | `JSONDecoderImpl+Unwrap.swift` | DateFormatter 非线程安全 |

### 注意事项
- 不破坏公共 API
- 加锁方案优先使用 `NSLock`（兼容 iOS 13+）
- 评估是否需要将 `SmartCodableOptions` 改为 per-decoder 配置

---

## Phase 3: 代码质量优化 - 重构

**状态：** 待开始

### 目标
消除代码重复，改善可维护性。

### 涉及问题
| # | 问题 | 说明 |
|---|------|------|
| 1 | `didFinishMapping` 在 KeyedContainer 和 UnkeyedContainer 中重复实现 | 提取到共享位置 |
| 2 | SmartAny 整数类型推断：10 种类型顺序尝试，约 20 行重复代码 | 简化为循环 |
| 3 | `SmartCompact.Array/Dictionary` 未遵循 `PropertyWrapperable` 协议 | 与其他属性包装器不一致 |
| 4 | `preconditionFailure` / `fatalError` 用于可恢复的错误 | 生产环境不应崩溃，应 throw |
| 5 | 日志代码无条件编译保护 | Release 构建中仍有运行时开销 |
| 6 | LogCache 无容量上限 | debugMode 开启时内存无限增长 |
| 7 | Encoder/Decoder 之间 snake_case 转换逻辑重复 | 提取到共享工具模块 |
| 8 | SmartDate.swift 重复 `import Foundation` | 清理 |

### 注意事项
- 每个重构点独立提交
- 不改变公开接口签名

---

## Phase 4: README 优化

**状态：** 待开始

### 目标
重新组织 README 结构，提升项目第一印象。

### 计划内容
- 重新组织结构（Quick Start -> 核心功能 -> 高级用法 -> 迁移指南 -> FAQ）
- 补充"为什么选择 SmartCodable"对比章节
- 预留 Benchmark 数据展示位
- 补充架构图 / 工作原理简图

---

## Phase 5: Benchmark 性能对比

**状态：** 待开始

### 目标
提供量化的性能对比数据，增强选型说服力。

### 计划内容
- 建立独立 Benchmark Target
- 对比对象：原生 Codable、SmartCodable、HandyJSON
- 覆盖场景：简单模型、嵌套模型、大数组（1000+）、类型不匹配容错
- 输出可视化数据（表格 / 图表）

### 注意事项
- 注明测试环境（设备、系统版本、Swift 版本）
- 提供可复现的运行脚本

---

## Phase 6: 补充单元测试

**状态：** 待开始

### 目标
提升测试覆盖率，保障重构信心。

### 计划内容
- 类型转换边界（Int 溢出、Float 精度、Bool/Int 区分）
- 每种 fallback 路径（缺失字段、类型错误、null 值）
- 嵌套模型、数组模型
- 属性包装器各场景
- Key Mapping 各策略

---

## Phase 7: HandyJSON 迁移工具 / 深度指南

**状态：** 待开始

### 计划内容
- API 对照表（HandyJSON API -> SmartCodable API）
- 常见迁移踩坑记录
- 可选：自动化迁移脚本

---

## Phase 8: 社区基础设施

**状态：** 待开始

### 计划内容
- CONTRIBUTING.md 贡献指南
- Issue / PR 模板
- 标注 `good first issue` 吸引贡献者

---

## 全局注意事项

| 项目 | 说明 |
|------|------|
| **不引入 Swift Macro 依赖** | 所有优化不新增 `swift-syntax` 依赖，保持当前分 subspec 的隔离策略 |
| **不破坏公共 API** | 代码优化只做内部重构，不改变公开接口签名 |
| **向后兼容** | 保持 Swift 5.0+ / iOS 13+ 的最低版本要求不变 |
| **分步提交** | 每个修复点独立提交，commit message 清晰说明改动内容和原因 |
