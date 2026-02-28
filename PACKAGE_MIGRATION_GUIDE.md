# SmartCodable Package 迁移指南

## 📋 变更概述

SmartCodable 现在提供了两种产品选择，让用户可以根据需求选择合适的版本：

### 🎯 新的产品结构

| 产品名称 | 依赖 | 适用场景 | 编译速度 |
|---------|------|---------|---------|
| **SmartCodable** | 无 swift-syntax | 不需要继承功能的项目 | ⚡️ 快 |
| **SmartCodableWithMacros** | 包含 swift-syntax | 需要 @SmartSubclass 继承功能 | 🐢 较慢 |
| **SmartCodableInherit** (已废弃) | 包含 swift-syntax | 向后兼容，建议迁移到 SmartCodableWithMacros | 🐢 较慢 |

---

## 🚀 使用方式

### 方式 1: 核心功能（推荐大多数用户）

如果你不需要类继承功能，使用这个版本可以获得更快的编译速度：

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/iAmMccc/SmartCodable.git", from: "6.0.1")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "SmartCodable", package: "SmartCodable")
        ]
    )
]
```

**特性支持：**
- ✅ 基础解码/编码
- ✅ 类型兼容和默认值
- ✅ 所有 PropertyWrapper (@SmartAny, @SmartIgnored, @SmartFlat 等)
- ✅ 解码策略和回调
- ✅ Struct 和 Class 的基础使用
- ❌ 不支持 @SmartSubclass 宏（类继承）

---

### 方式 2: 完整功能（需要继承支持）

如果你需要使用 `@SmartSubclass` 进行类继承：

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/iAmMccc/SmartCodable.git", from: "6.0.1")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "SmartCodableWithMacros", package: "SmartCodable")
        ]
    )
]
```

**特性支持：**
- ✅ 所有核心功能
- ✅ @SmartSubclass 宏支持
- ✅ 类继承场景

**注意事项：**
- 需要 Xcode 15+ 和 Swift 5.9+
- 首次构建会下载 swift-syntax 依赖（可能较慢）
- 编译时间会比核心版本长

---

## 🔄 迁移指南

### 从旧版本迁移

#### 场景 1: 你没有使用 @SmartSubclass

**之前：**
```swift
dependencies: [
    .product(name: "SmartCodable", package: "SmartCodable")
]
```

**现在：**
```swift
// 无需修改，继续使用 SmartCodable
dependencies: [
    .product(name: "SmartCodable", package: "SmartCodable")
]
```

✅ 无需任何代码修改，编译速度会更快！

---

#### 场景 2: 你使用了 @SmartSubclass

**之前：**
```swift
dependencies: [
    .product(name: "SmartCodable", package: "SmartCodable"),
    .product(name: "SmartCodableInherit", package: "SmartCodable")
]
```

**现在（推荐）：**
```swift
// 使用新的统一产品
dependencies: [
    .product(name: "SmartCodableWithMacros", package: "SmartCodable")
]
```

**或者（向后兼容）：**
```swift
// 保持原样也可以工作，但建议迁移
dependencies: [
    .product(name: "SmartCodable", package: "SmartCodable"),
    .product(name: "SmartCodableInherit", package: "SmartCodable")
]
```

✅ 无需修改代码，只需更新 Package.swift

---

## 💡 如何选择？

### 使用 SmartCodable（核心版本）如果：
- ✅ 你只使用 Struct
- ✅ 你的 Class 不需要继承
- ✅ 你想要更快的编译速度
- ✅ 你想减少依赖体积

### 使用 SmartCodableWithMacros（完整版本）如果：
- ✅ 你需要使用 @SmartSubclass
- ✅ 你有类继承的场景
- ✅ 你需要在子类中重写 SmartCodable 协议方法

---

## 🔧 技术细节

### 依赖关系

```
SmartCodable (核心)
├── 无外部依赖
└── 包含所有核心功能

SmartCodableWithMacros (完整)
├── SmartCodable (核心)
├── SmartCodableInherit (宏暴露层)
└── swift-syntax (宏实现)
    └── SwiftSyntax
    └── SwiftSyntaxMacros
    └── SwiftCompilerPlugin
    └── ...
```

### swift-syntax 版本

```swift
.package(url: "https://github.com/swiftlang/swift-syntax", from: "509.0.0")
```

- 支持 Swift 5.9+
- 使用 `from:` 语义化版本，兼容性更好
- 自动支持未来的 swift-syntax 版本

---

## 📊 性能对比

| 指标 | SmartCodable | SmartCodableWithMacros |
|-----|-------------|----------------------|
| 首次编译时间 | ⚡️ 快 | 🐢 慢（需下载 swift-syntax） |
| 增量编译时间 | ⚡️ 快 | 🔶 中等 |
| 包大小 | 📦 小 | 📦 大 |
| 功能完整性 | 🔶 核心功能 | ✅ 完整功能 |

---

## ❓ 常见问题

### Q1: 我应该使用哪个版本？

**A:** 如果不确定，先使用 `SmartCodable`（核心版本）。只有在遇到类继承需求时，再切换到 `SmartCodableWithMacros`。

### Q2: 切换版本需要修改代码吗？

**A:** 不需要！只需修改 Package.swift 中的产品名称即可。

### Q3: SmartCodableInherit 还能用吗？

**A:** 可以，但已标记为废弃。建议迁移到 `SmartCodableWithMacros`，它们功能完全相同。

### Q4: 为什么要分成两个产品？

**A:** 
- swift-syntax 是一个很大的依赖（编译慢、体积大）
- 大多数用户不需要继承功能
- 分离后，不需要宏的用户可以获得更快的编译速度

### Q5: 这个改动会破坏现有代码吗？

**A:** 不会！这是完全向后兼容的改动：
- 原有的 `SmartCodable` 产品继续工作
- 原有的 `SmartCodableInherit` 产品继续工作
- 只是新增了 `SmartCodableWithMacros` 作为推荐选项

---

## 🎯 推荐实践

### 新项目

```swift
// 1. 先使用核心版本
dependencies: [
    .product(name: "SmartCodable", package: "SmartCodable")
]

// 2. 如果需要继承，再升级到完整版本
dependencies: [
    .product(name: "SmartCodableWithMacros", package: "SmartCodable")
]
```

### 现有项目

```swift
// 1. 评估是否使用了 @SmartSubclass
// 2. 如果没有，保持使用 SmartCodable（自动获得性能提升）
// 3. 如果有，迁移到 SmartCodableWithMacros
```

---

## 📝 更新日志

### 版本 6.0.1

- 🟢 新增 `SmartCompact` 命名空间（Array / Dictionary 宽容解析）
- ✨ 新增 `SmartCodableWithMacros` 产品
- 🔧 修改 swift-syntax 版本约束为 `from: "509.0.0"`
- 📚 改进产品文档和注释
- ⚠️ 标记 `SmartCodableInherit` 为废弃（但仍可用）

---

## 🤝 贡献

如果你有任何问题或建议，欢迎：
- 提交 Issue
- 发起 Discussion
- 提交 Pull Request

---

## 📖 相关资源

- [SmartCodable 主仓库](https://github.com/iAmMccc/SmartCodable)
- [Swift Package Manager 文档](https://swift.org/package-manager/)
- [swift-syntax 仓库](https://github.com/swiftlang/swift-syntax)
- [Swift Macros 文档](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/)
