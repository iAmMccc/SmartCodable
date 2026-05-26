---
name: Bug Report
about: 报告一个 Bug / Report a bug
title: '[Bug] '
labels: bug
assignees: ''
---

## 环境 / Environment

- SmartCodable 版本：
- Swift 版本：
- Xcode 版本：
- 平台（iOS/macOS/tvOS 等）：
- 安装方式（SPM / CocoaPods）：

## 描述 / Description

简要描述遇到的问题。

## 复现代码 / Reproduce

提供最小可复现的代码（包含 JSON 数据、Model 定义、调用代码）：

```swift
// JSON
let json = """
{

}
"""

// Model
struct Model: SmartCodableX {

}

// 调用
let model = Model.deserialize(from: json)
```

## 期望结果 / Expected

描述期望的解析结果。

## 实际结果 / Actual

描述实际的解析结果。

## SmartSentinel 日志 / Sentinel Log（可选）

```
// 开启 SmartSentinel.debugMode = .verbose 后的输出
```
