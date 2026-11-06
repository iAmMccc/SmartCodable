# 更新日志

本文件记录用户可观察的版本变化、兼容范围和迁移方式。已发布版本的日期采用 GitHub Release 的 `published_at`（UTC）；仅有 Git 标签而没有 Release 记录的历史版本明确标为“发布日期未记录”，不以提交日期代替发版日期。未发布条目在正式发布时填写实际日期，并创建同名版本标签。

## 7.1.0 — 未发布

本次计划版本为 **7.1.0**：除了问题修复，还新增了向下兼容、需要显式启用的公共能力，按[语义化版本规则](https://semver.org/lang/zh-CN/)递增次版本号。开发分支名称不决定最终发布版本。

### 新增

- `SmartJSONDecoder.smartUnkeyedDecodingStrategy = .consumeOnce`：自定义非键控可选元素解码中，null、成功及容错回退只消费一个位置；容器末尾返回 nil 且不推进游标。默认仍为 `.legacy`。
- `SmartJSONEncoder.smartDynamicValueEncodingStrategy = .recursive`：递归编码动态容器内的 Date、Data、URL 和 Encodable 模型，使用当前 encoder 的日期、数据和键策略，保留字典数据键；不支持的嵌套叶子抛出带 codingPath 的错误。默认仍为 `.legacy`。
- `SmartCodableOptions.compactElementStrategy = .convert`：为 `@SmartCompact.Array` 显式启用字符串到数值/布尔的转换及普通 Codable 元素支持。此全局选项同时影响元素编码；需要稳定调用策略时，在编解码期间保持配置不变。默认仍为 `.legacy`。

### 修复

- 在整数截断或舍入前按原始值检查范围，避免宽整数及极小小数越界被浮点近似误接受；保留十六进制数字字符串支持。
- 修正有限浮点数字符串解码、颜色往返、属性包装器配置恢复及紧凑模型数组过滤。
- 在配置保持不变时，隔离共享 decoder 的调用上下文与日志会话，避免向调用方 `userInfo` 写入内部会话信息。
- `SmartUpdater` 按根字段身份合并别名，避免更新一个字段时覆盖另一个同名字段；保持未更新的可编码字段；Codable 之外的运行时状态仍需通过 `preserving` 显式保留。
- 编码 transformer 按原始属性 key 匹配，避免输出别名错选其他属性的 transformer；编码失败后正确释放模型快照。
- 修正顶层 Bool、String 和数值的 JSON 编码；`@SmartPublished` 在宿主使用自定义 `objectWillChange` publisher 时仍能保存赋入的新值。
- `.none` 日志模式抑制业务打印和回调；加强默认值、可选值、显式嵌套容器及示例结果的回归验证。

### 有意保留的行为修正

- **URL 转义与 fragment**：已转义的 `a%20b` 不再重复编码成 `a%2520b`，输入中的 `#` 按 URL fragment 处理。若业务需要字面量 `#` 成为路径内容，请在输入中使用 `%23` 或提供业务专用 transformer。包含已编码序列与非法字符的混合字符串仍受 Foundation URL 解析行为影响。
- **显式嵌套编码的位置**：手写 `encode(to:)` 的 `nestedContainer` / `nestedUnkeyedContainer` 将值写入请求的层级和数组位置，保留宿主兄弟字段；失败后同 key 的恢复编码不会继承失败模型的 transformer。依赖旧版错误层级或字段错位输出的调用方，应按正确 JSON 结构更新服务端契约或自定义编码；不提供恢复错误位置的兼容开关。
- **越界数值**：原始值越界时回退默认值，而不是在截断、舍入或精度损失后勉强装入目标类型。例如 UInt8 的 `"255.4"` 和 `"-0.4"` 均越界；`"254.6"` 可在 `.rounded` 下得到 255。请在调用方显式做业务需要的钳位处理。

### 兼容范围与升级

- `SmartDecodingOption`、`SmartEncodingOption` 保持 7.0.1 的 case 集合；现有穷举 switch 不需要增加分支。
- 未选择新模式时，保留普通可选数组、Compact 可选模型、模型完成回调以及动态值编码的既有边界。兼容不意味着保留上述已明确修复的错误输出。
- 字典属性默认只接受 JSON 对象，嵌入的 JSON 对象字符串需要调用方预解析或显式 transformer。
- `designatedPath` 仍跳过空/空白路径段，真实缺失组件仍失败；需要严格语法的调用方应先验证路径。
- `SmartJSONDecoder.smartDecode` 的 String 入口保留对象/数组输入域；顶层 JSON fragment 使用 Data 入口。
- `@SmartAny` 默认对桥接域外的普通 Encodable 值输出 null；`@SmartCompact.Dictionary` 默认接受直接 Encodable 值并传播错误，但省略只能经 JSON 桥表达的异构容器。深层运行时值需要显式选择 `.recursive`。
- SwiftPM 核心库仍要求 Swift 5.9+、iOS 13+，不依赖 SwiftSyntax。Example 工程要求 iOS 26+，不代表核心库提高最低系统版本。类继承宏由独立的 SmartCodableMacro 包提供，不随核心库发布自动更新；7.x 不通过 CocoaPods 发布。

详细使用方式与有限保证见[兼容与恢复选项](Document/CompatibilityOptions.md)及[测试契约](Documentation/Testing/contracts.md)。

7.1.0 标签发布后，SwiftPM 可使用：

```swift
.package(url: "https://github.com/iAmMccc/SmartCodable.git", from: "7.1.0")
```

## 已发布版本

以下日期和摘要来自各版本的公开 Release；预发布版本保留原标签名称。

| 版本 | 发布日期（UTC） | 变更说明 | 来源 |
| --- | --- | --- | --- |
| `7.0.1` | 2026-09-24 | 修复 SmartFlat 嵌套解码上下文污染、独立模型默认引用值共享、属性包装器宿主配置恢复与转换回调重复执行；加强上下文复用、并发 TSan 和 SmartHexColor 平台回归验证。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/7.0.1) |
| `7.0.1-beta.1` | 2026-09-17 | 预发布修复与 7.0.1 正式说明一致：修复嵌套解码上下文、引用默认值共享及属性包装器回调问题，并补充上下文复用、并发 TSan 与 SmartHexColor 回归验证。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/7.0.1-beta.1) |
| `6.0.1` | 2026-01-22 | 新增 `SmartCompact.Array` 与 `SmartCompact.Dictionary` 容错包装器，分别跳过无法解析的数组元素和字典键值，并统一命名空间。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/6.0.1) |
| `6.0.0` | 2025-12-18 | 将公开协议名调整为 `SmartCodableX`，Release 说明为解决打包 XCFramework 时的命名空间冲突。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/6.0.0) |
| `5.0.2` | 2025-05-08 | 新增继承支持：通过 `@SmartSubclass` 为子类扩展 SmartCodable 属性解码能力。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/5.0.2) |
| `4.4.0` | 2025-05-06 | 新增 `@SmartHexColor`、`@SmartDate`；优化 CGFloat 与解析性能并修复默认值和 `[Any]` 编码转换器问题；移除 `SmartColor`。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.4.0) |
| `4.3.8` | 2025-03-28 | 优化 `@SmartFlat` 的编码实现。Release 正文为空；摘要依据 Release 标题及本地 tag 提交/差异核对。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.3.8) |
| `4.3.0` | 2024-11-25 | 升级日志系统：提升日志性能与表达、支持导出，并改进 unkeyedContainer 等日志格式。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.3.0) |
| `4.2.6` | 2024-10-31 | 优化继承场景下父类属性解析；新增 `SmartAny` 修饰 Model 类型的支持。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.2.6) |
| `4.2.5` | 2024-10-18 | 优化 KeyMap / 自定义 key 映射规则。Release 正文为空；摘要由 Release 标题和 tag 提交记录交叉核对。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.2.5) |
| `4.2.3` | 2024-10-12 | 修复非基础类型自定义解析与 null key 映射判断问题；新增 `FastTransformer` 快捷值转换器。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.2.3) |
| `4.2.0` | 2024-09-27 | 支持 Combine `@Published` 属性解析、编码时忽略指定属性、编码 options，并将 Data 编解码限定为 Base64。Release 标题写作“V4.1.12 发布公告”，此处按 tag `4.2.0` 归档并保留该标题差异。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.2.0) |
| `4.1.7` | 2024-08-27 | 修复解析失败进入兼容分支时的崩溃，并处理 NaN 与超出 Int 范围的输入。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.1.7) |
| `4.1.3` | 2024-07-29 | 优化 `SmartUpdater` 实现。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.1.3) |
| `4.1.1` | 2024-07-05 | 改进浮点数转字符串的精度处理。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.1.1) |
| `4.0.0` | 2024-06-13 | 新增 watchOS、visionOS、tvOS 支持及自定义 encoder/值转换策略；改进 enum 解析、文档，并修复并发日志中的内存问题。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/4.0.0) |
| `3.4.3` | 2024-05-15 | 优化包含 `SmartAny` 的模型转 JSON 失败场景。 | [Release](https://github.com/iAmMccc/SmartCodable/releases/tag/3.4.3) |

## 7.0 系列标签记录

以下标签没有对应的 GitHub Release 记录，因此发布日期未记录；说明按源码变更范围整理。`7.0` 与 `7.0.0` 指向同一提交。

| 版本标签 | 发布日期 | 变更说明 | 来源 |
| --- | --- | --- | --- |
| `7.0.0` | 未记录 | 相对 7.0.0-beta.1 仅调整两处源文件头注释，没有新增功能差异。 | [源码](https://github.com/iAmMccc/SmartCodable/tree/7.0.0) · [变更](https://github.com/iAmMccc/SmartCodable/compare/7.0.0-beta.1...7.0.0) |
| `7.0.0-beta.1` | 未记录 | 7.0 大版本预发布起点。提交范围合入 6.1.0 开发线，修复 UnkeyedContainer 解码和全局可变状态线程安全问题；重整 Package.swift、核心/Macro 源码边界、测试支撑、Example 与中英文文档。 | [源码](https://github.com/iAmMccc/SmartCodable/tree/7.0.0-beta.1) · [变更](https://github.com/iAmMccc/SmartCodable/compare/6.0.8...7.0.0-beta.1) |
| `7.0` | 未记录 | 该 tag 与 `7.0.0` 指向同一提交，复用相同的源码范围；没有独立于 `7.0.0` 的新增提交或发布说明。 | [源码](https://github.com/iAmMccc/SmartCodable/tree/7.0) · [变更](https://github.com/iAmMccc/SmartCodable/compare/7.0.0-beta.1...7.0) |

## 更早的标签索引

其余历史标签没有可核实的 GitHub Release 日期或发布说明。这里只保留源码和提交入口，不将标签日期当作发布日期，也不推断每个标签都曾单独发版。

<details>
<summary>查看 149 个历史标签</summary>

| 版本标签 | 发布日期 | 源码记录 |
| --- | --- | --- |
| `6.0.8` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/6.0.8) · [提交](https://github.com/iAmMccc/SmartCodable/commit/90a68a72a4e50f30f9e1a3639ac88734db733b16) |
| `6.0.7` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/6.0.7) · [提交](https://github.com/iAmMccc/SmartCodable/commit/cb8bbeca33f7ec9288946e604836941774397eb1) |
| `6.0.6` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/6.0.6) · [提交](https://github.com/iAmMccc/SmartCodable/commit/184e67364aff53db772b184e4bcf502a9a4f74e5) |
| `6.0.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/6.0.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/5ae61422948fc6f94f6a72e234f1b77bbe9facc1) |
| `6.0.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/6.0.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/18b8cf317fa6e85f28e071c28e3fe0ee893362d0) |
| `6.0.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/6.0.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/4c631830100824373f604b3b4ffa023681f61c2a) |
| `6.0.3-beta.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/6.0.3-beta.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/4c631830100824373f604b3b4ffa023681f61c2a) |
| `6.0.3-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/6.0.3-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/8464f63feeeb179b09662439cb460bcffd853250) |
| `6.0.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/6.0.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/91bdd63395fdf5aaa6f60c4e454cc09e6eaaf5e8) |
| `5.2.0-beta.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.2.0-beta.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/04063fc6294a6ec09b29c5fbb832e7ee407f274c) |
| `5.2.0-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.2.0-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/537e2cfbc268da7544a8d6ed95b9bd5c22a4901d) |
| `5.1.8` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.8) · [提交](https://github.com/iAmMccc/SmartCodable/commit/13e2c57d055a972b86deb76c627cbbcd89cdf170) |
| `5.1.7` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.7) · [提交](https://github.com/iAmMccc/SmartCodable/commit/a0efc2c1c6ae7f0658a430e7c59044a4d6e2e94f) |
| `5.1.6` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.6) · [提交](https://github.com/iAmMccc/SmartCodable/commit/28c54bf3b0b5a855f09c584e13ebcbc1404122f0) |
| `5.1.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/fd024ffb7aa014b0ecd424709b386674bd6f4091) |
| `5.1.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/2b01d14882112c9488c61e1beea686e786e37c66) |
| `5.1.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/95b574f7b6dd189e134e696a4334c27911bbdd23) |
| `5.1.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/1eae39ab33266a8232867c1255016430511fe274) |
| `5.1.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/d6a45d16e622dbd0388b9d48c76318cfc19eba61) |
| `5.1.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/64222c2a26ef7c39723a011888a4c8dd87d235ba) |
| `5.1.0-beta.7` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.0-beta.7) · [提交](https://github.com/iAmMccc/SmartCodable/commit/c32b33310d09baffdc54edf323814ec4f6c14f4b) |
| `5.1.0-beta.6` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.0-beta.6) · [提交](https://github.com/iAmMccc/SmartCodable/commit/4fa09f58700704bc16bcb575896745d1deb151fa) |
| `5.1.0-beta.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.0-beta.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/41fc25a9a6aac24357ff6192b5ba2d665e03c6b9) |
| `5.1.0-beta.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.0-beta.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/8330fc40d19d37cb76d2ebd0575f6a107818e738) |
| `5.1.0-beta.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.0-beta.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/28864e30c6b9cf60418be8ca9f8c4e61f6e87bf9) |
| `5.1.0-beta.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.0-beta.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/a502811ed47f359f62a9557c6252543ceb8f2bc8) |
| `5.1.0-beta.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.0-beta.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/93089f4a5b886ce0e1c5303f0652acd773984a07) |
| `5.1.0-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.1.0-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/b7ff6d89bd942bca3c9478118f7919595efcd72b) |
| `5.0.15` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.15) · [提交](https://github.com/iAmMccc/SmartCodable/commit/f362352d74f4c3e7e29362e64590756280c77ad1) |
| `5.0.14` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.14) · [提交](https://github.com/iAmMccc/SmartCodable/commit/f91a085088debdfacee5d2db5db47e07940e8710) |
| `5.0.13` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.13) · [提交](https://github.com/iAmMccc/SmartCodable/commit/53e0cab12b547f566d4055b159753ed9b580bf2c) |
| `5.0.12` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.12) · [提交](https://github.com/iAmMccc/SmartCodable/commit/9e0914d5c8978247c2b94f0d7b8d7ee810f78ec5) |
| `5.0.11` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.11) · [提交](https://github.com/iAmMccc/SmartCodable/commit/3579a088f19d7dfec388e22ed08e8f26efe3d84f) |
| `5.0.10` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.10) · [提交](https://github.com/iAmMccc/SmartCodable/commit/7a963ac72927bb6518f37f8d1da5bbf0d3403e29) |
| `5.0.9` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.9) · [提交](https://github.com/iAmMccc/SmartCodable/commit/3ebfb65c9998a82429a9d1e3ca4a25aab12fee28) |
| `5.0.8` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.8) · [提交](https://github.com/iAmMccc/SmartCodable/commit/68f0907f7295cb6a3bbbbc1852a53de6be9a3630) |
| `5.0.7` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.7) · [提交](https://github.com/iAmMccc/SmartCodable/commit/3007677bbb8ec44743e3d3cea7d947b0b7aca147) |
| `5.0.6` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.6) · [提交](https://github.com/iAmMccc/SmartCodable/commit/06a819030ca2ad4e68c9946e890f9dc8795fa2b8) |
| `5.0.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/befc5cec24e9a3686f3437c079aa293037118ae8) |
| `5.0.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/0c5b9bfb9c2914f851822ef42e46bf776828c4a0) |
| `5.0.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/c59afdf76d002d59a8f2817fac19fe913cf42eb6) |
| `5.0.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/9624794464fc945618b669f05a26ec188c58939f) |
| `5.0.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/fa3595b93620b0e89daa04ea31757a1f988c12d5) |
| `5.0.0-beta.6` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.0-beta.6) · [提交](https://github.com/iAmMccc/SmartCodable/commit/3613df480362b39979eac4711b6509e4a445bc47) |
| `5.0.0-beta.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.0-beta.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/42cd19f1a0f0fe7d24a04a3185f97e00c7d5ef68) |
| `5.0.0-beta.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.0-beta.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/ae3ce6b6353c8b3254d2b6bec8dc1797b6228a84) |
| `5.0.0-beta.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.0-beta.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/45f45218ae3685b11e9dd27cf402584fbd6f962a) |
| `5.0.0-beta.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.0-beta.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/dea732657c4747546d9ead69b21a445720bca7f8) |
| `5.0.0-beta.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.0-beta.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/aad8dd1758ae64689d70ab06134610e6f0f5eee1) |
| `5.0.0-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/5.0.0-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/c2eea3fb5dce879ead2b71ef5578b5660d899263) |
| `4.4.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.4.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/ad1b36d983b676295f9e44fb2dc7d33200f3c873) |
| `4.4.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.4.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/faa99cc192b767b1c79cb59941b64eef1ea57f77) |
| `4.4.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.4.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/1efff0ad190bde5598a66ce4708384833195d8b1) |
| `4.4.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.4.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/305f7777adfc7831e6db3db4bf8a6c4ced61ecd8) |
| `4.4.0-beta.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.4.0-beta.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/4b1b3e392ecd2260de6068e62f3e19352ee9c6b1) |
| `4.4.0-beta.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.4.0-beta.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/9ac6cb26349ee59abe923271b61f815454e8fcc7) |
| `4.4.0-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.4.0-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/e7c482568dd4bb38bfebe508f62560e5eb599602) |
| `4.3.9` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.3.9) · [提交](https://github.com/iAmMccc/SmartCodable/commit/7ec57b4eeeb75d89a315dff5835507de8bb4b5bb) |
| `4.3.7` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.3.7) · [提交](https://github.com/iAmMccc/SmartCodable/commit/6283163c1a649a6bacd4bf259bec9180cc15bc69) |
| `4.3.7-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.3.7-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/2f1e3fff0efdcce93471aaeacf6d0513c81ca63b) |
| `4.3.6` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.3.6) · [提交](https://github.com/iAmMccc/SmartCodable/commit/f3071a135037131b88594a3600494bd4a3094b69) |
| `4.3.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.3.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/51cf553933ebd0e9d65b17da479f2233cc4486f6) |
| `4.3.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.3.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/1d85a3cdfe921f5099672b8ce4ae46a25b13260c) |
| `4.3.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.3.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/7d58a80405bdf0c9eed3da5507233c3d3b1db502) |
| `4.3.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.3.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/c926e214e5d62306bb9303262e373d13cfbd17b1) |
| `4.3.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.3.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/9ab82ed85ae88fd8e183166f2c57a0621fd616c7) |
| `4.3.0-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.3.0-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/78440b7a5ffc7315350a4ae2850d25a99ddab77c) |
| `4.2.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.2.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/26a667a27e3ca413f08f6b9849fd247a135fac43) |
| `4.2.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.2.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/b17d751ec42063b40383d0649c77b69e30bc863d) |
| `4.2.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.2.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/3c8bac893647f75eac23d7cd1f0054a39a71c011) |
| `4.1.11-beta.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.11-beta.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/56cccc31ead16896c7c83d27ecd5a4bd62560401) |
| `4.1.11-beta.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.11-beta.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/217d9e2cfd156d3922d80f9b6722aaa791d11adc) |
| `4.1.11-beta.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.11-beta.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/1bab7c6a6422d46cd05b991ecce68b2514a76c3f) |
| `4.1.11-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.11-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/14fa21541de7bc7d1cc66d9af6983f815c1fbf6e) |
| `4.1.10` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.10) · [提交](https://github.com/iAmMccc/SmartCodable/commit/6e965539c83fc20a25b69f937d455c3bdeaff985) |
| `4.1.9` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.9) · [提交](https://github.com/iAmMccc/SmartCodable/commit/d69d3b92ab4cd302553bb8e541f8ad6744df2f6a) |
| `4.1.8` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.8) · [提交](https://github.com/iAmMccc/SmartCodable/commit/c3e4664bfad019ebb608e793579941d07f792ca6) |
| `4.1.6` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.6) · [提交](https://github.com/iAmMccc/SmartCodable/commit/83c85f02832d5878826f3896a04b2d052d0d42da) |
| `4.1.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/5c85d7fdb693e18fcb373611204e44a7253b3d37) |
| `4.1.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/c37dda31bf6a76ac9513d4422c35e3253ad734f7) |
| `4.1.3-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.3-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/32a3282889ee335c21db01ef863927ef33bc26d0) |
| `4.1.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/48d5913de8c934a9f93654d16f9128e997991473) |
| `4.1.2-beta.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.2-beta.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/d9340d7a50575753e53db95c74cf431016b7a722) |
| `4.1.2-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.2-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/d6f7b8b77a74bf016912712eaf1cc666cb524eab) |
| `4.1.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/bbe476173ecda03395a122167ed09d2fd3aa26bc) |
| `4.1.0-beta.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.0-beta.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/30c23cbed72bda25bf5a2d92b54000b378a026ab) |
| `4.1.0-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.1.0-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/6f1719923f5533c195355d9cd1a2523a521fa49a) |
| `4.0.9` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.9) · [提交](https://github.com/iAmMccc/SmartCodable/commit/3ebfb65c9998a82429a9d1e3ca4a25aab12fee28) |
| `4.0.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/3c822c163b0ebc686619d87ed87c7606328d5d2f) |
| `4.0.3.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.3.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/c79b0ba6099331f668b3dce4751ebdd4906f0d48) |
| `4.0.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/1bff60f8033f07cb540277446a8ef7832a269dd1) |
| `4.0.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/6bfbc3c691cdd2a2533f6be516f123bb392cf1b8) |
| `4.0.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/bd0a3123b69c81a08f76d75f9cb71b20a673a88b) |
| `4.0.0-beta.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.0-beta.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/304117236b84d45c2d5563283f1650c58e5f49e0) |
| `4.0.0-beta.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.0-beta.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/02d3b38144c236c7901315d075858d206c79752f) |
| `4.0.0-beta.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.0-beta.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/fcf98b89f52c2b10de96c97c7b17b0fe591af100) |
| `4.0.0-beta.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.0-beta.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/d9872fe354c2eeb34f63fd86ef8996d4eec0bdca) |
| `4.0.0-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/4.0.0-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/5a4f22779aea458aa248e2bb421c2fed89f4b9bf) |
| `3.4.6` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.4.6) · [提交](https://github.com/iAmMccc/SmartCodable/commit/d869b7e3b4720baf1331de39e253bd92db22998b) |
| `3.4.6-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.4.6-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/90f2005cca4241b9d015025eba6e2d616af6b947) |
| `3.4.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.4.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/f9297874793a5d628ebd6670b7b614288504145e) |
| `3.4.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.4.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/cc39f3105c4547aff119f03a3f1b3151a66f073e) |
| `3.4.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.4.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/0abd7a4d3e7b365eadcbeefff36cebd0b0315e55) |
| `3.4.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.4.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/267bb2c2c94b8e453f455aa11fc8b012035ce2e8) |
| `3.4.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.4.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/f23f4ab0891cf6c8b4392a541071a6e021f8d48a) |
| `3.3.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.3.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/78aea98f59d9905ce3178d63b2c3cdb5a65d4330) |
| `3.3.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.3.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/b74be25d69d77b248bae32843044c67c1e3dfe21) |
| `3.3.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.3.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/3411c9dc85f7336e27dce95c356e2ee1cf4f0832) |
| `3.2.9-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.2.9-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/2da1fc1f94c19aa662e177d5512dda4db273668e) |
| `3.2.8-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.2.8-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/1bae6848860a7408937e88cb6262f94850651ea1) |
| `3.2.7-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.2.7-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/bdd91288cdc4fae35ea6a8b2f02abff82d2d7286) |
| `3.2.6-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.2.6-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/9bdcad26bac262783c471096572c66bbc1fc6679) |
| `3.2.5-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.2.5-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/a3e35f66204d1b2ed17cc1bc9884827b480eceaa) |
| `3.2.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.2.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/b4ba42e1b2d684bce49cf85e4dbfd9708fe79a1c) |
| `3.2.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.2.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/6650252905d48bb72a6747c0817af68f8a5f0939) |
| `3.2.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.2.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/81fcccff2270437935259fbf835c758e6021bacd) |
| `3.2.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.2.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/8f7cb7cb2be0825f7478f2aeb8dc1bcae573d931) |
| `3.2.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.2.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/28392e1e7743ba7d915b861bde7dd39d10f71404) |
| `3.1.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.1.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/479a9856c9a41f7487e35076ccb848a51e2b8ec9) |
| `3.0.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.0.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/91376f5a85a13e1e123293c5b02600694dfd72dc) |
| `3.0.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.0.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/1ab53ea45178f6041200064867040ecf9cb39c38) |
| `3.0.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.0.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/15c5714de6983fe8f2c74698c39e5bdd4aebd6b4) |
| `3.0.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.0.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/395d1bdd2c6fcddc355316dee6f409e2438e4778) |
| `3.0.1-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.0.1-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/0e2a4476039e0c1cccc1d09b6fa0e0e85b8e37c6) |
| `3.0.0-beta` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/3.0.0-beta) · [提交](https://github.com/iAmMccc/SmartCodable/commit/1adb171138e4eeef5de7ca76de292bd947e2aba4) |
| `2.3.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.3.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/f71f8967fb6ddaf8ea7b9f4fd2c5caa8f87cfb3e) |
| `2.3.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.3.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/14a0fd9018b318508acd2c65681b0946cb7ae0fc) |
| `2.2.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.2.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/b5f396e340186fde7056e8314383af0fcbac9a0a) |
| `2.2.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.2.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/589b34c383addc2f29dfb9dba984f0b3e1f7a1ba) |
| `2.2.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.2.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/b1e22406918055c4e771bf6b613a59b765afe613) |
| `2.2.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.2.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/f3b59bb422a7bb1e47dd27a45562a9674cd292bb) |
| `2.2.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.2.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/bdc1a05c5d629289de001c307b0a1a6d64159f6b) |
| `2.1.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.1.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/5394b878eb86f2603c7cd61b84b4d88b6940a7cd) |
| `2.0.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.0.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/d2b7f47e1c25c48c73ac2e858dd659cae71d5f2f) |
| `2.0.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.0.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/3a083e405ad6f7305be295d4b11b699c1201ae86) |
| `2.0.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.0.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/d979df83c7bf4169f342dd62b4bf5b276b07cc0b) |
| `2.0.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/2.0.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/f7ae6e76b7d38dbe8dfb3bf73f5134e1a6d60a09) |
| `1.2.5` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.2.5) · [提交](https://github.com/iAmMccc/SmartCodable/commit/97ff6d96f2877dd2045d589f800b0829db259c31) |
| `1.2.4` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.2.4) · [提交](https://github.com/iAmMccc/SmartCodable/commit/052ab43d2b587414018690337b47fc4bb26c9dc4) |
| `1.2.3` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.2.3) · [提交](https://github.com/iAmMccc/SmartCodable/commit/e89e638bf1dd688771b18736e5a5226b7219abd9) |
| `1.2.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.2.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/1d2fa0fd24056123d8d9d05d587fd53a203c1842) |
| `1.2.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.2.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/50dd558432106588a2e4eac75f7fc72ce19785cf) |
| `1.2.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.2.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/f6672380db6d821fa37e00a7f18f91a9d4d6eaaf) |
| `1.1.2` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.1.2) · [提交](https://github.com/iAmMccc/SmartCodable/commit/12c8362433e984cf7ce81ae111ec4222fa25df2b) |
| `1.1.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.1.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/31baf59f03de2cdcc0750dbc1ec02fec0124e436) |
| `1.1.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.1.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/cbd96a6a45b97dc7c531bbdcff137ac05f15707f) |
| `1.0.1` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.0.1) · [提交](https://github.com/iAmMccc/SmartCodable/commit/c253e19f6f625f3935f341484eefe3918c643b47) |
| `1.0.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/1.0.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/c253e19f6f625f3935f341484eefe3918c643b47) |
| `0.1.0` | 未记录 | [源码](https://github.com/iAmMccc/SmartCodable/tree/0.1.0) · [提交](https://github.com/iAmMccc/SmartCodable/commit/c253e19f6f625f3935f341484eefe3918c643b47) |

</details>
