# SmartCodable 优化工作计划

## 总览

基于对项目的全面审查，制定以下分阶段优化计划。每个 Phase 独立可交付，按优先级排序。

---

## Phase 1-3: 代码质量优化

**状态：** 已完成  
**详情：** [CodeOptimization.md](CodeOptimization.md)

包含：Bug 修复、拼写修正、线程安全、重构评估。

---

## Phase 4: README 优化

**状态：** 已完成

### 计划内容
- 重新组织结构（Quick Start → 核心功能 → 高级用法 → 迁移指南 → FAQ）
- 补充"为什么选择 SmartCodable"对比章节
- 预留 Benchmark 数据展示位
- 补充架构图 / 工作原理简图

---

## Phase 5: Benchmark 性能对比

**状态：** 待开始

### 计划内容
- 建立独立 Benchmark Target
- 对比对象：原生 Codable、SmartCodable、HandyJSON
- 覆盖场景：简单模型、嵌套模型、大数组（1000+）、类型不匹配容错
- 输出可视化数据（表格 / 图表）
- 注明测试环境（设备、系统版本、Swift 版本），提供可复现的运行脚本

---

## Phase 6: 补充单元测试

**状态：** 待开始

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
- API 对照表（HandyJSON API → SmartCodable API）
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
