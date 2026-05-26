import UIKit

enum DemoCatalog {

    static var allSections: [DemoSection] {
        [
            DemoSection(title: "1. 基础使用", items: [
                DemoEntry(title: "基础解码", subtitle: "deserialize / 数组 / designatedPath",
                          make: { BasicDecodeDemoViewController() }),
                DemoEntry(title: "可选与默认值", subtitle: "字段缺失 / null / 容错兜底",
                          make: { OptionalAndDefaultsDemoViewController() }),
                DemoEntry(title: "类型转换", subtitle: "String ↔ Number ↔ Bool 互转",
                          make: { TypeCoercionDemoViewController() }),
                DemoEntry(title: "Key 映射", subtitle: "mappingForKey 单 / 多 key",
                          make: { KeyMappingDemoViewController() }),
                DemoEntry(title: "Value 转换", subtitle: "mappingForValue / 日期 / 自定义 Transformer",
                          make: { ValueTransformDemoViewController() }),
                DemoEntry(title: "编码", subtitle: "toJSONString / toDictionary / 数组",
                          make: { EncodeDemoViewController() }),
            ]),
            DemoSection(title: "2. 解码策略", items: [
                DemoEntry(title: "解码前预处理", subtitle: "didFinishMapping 之前的清洗",
                          make: { PreDecodeStrategyDemoViewController() }),
                DemoEntry(title: "解码中策略", subtitle: "全局 vs 局部 SmartDecodingOption",
                          make: { InDecodeStrategyDemoViewController() }),
                DemoEntry(title: "解码后回调", subtitle: "didFinishMapping + 混合策略",
                          make: { PostDecodeStrategyDemoViewController() }),
            ]),
            DemoSection(title: "3. 调试日志", items: [
                DemoEntry(title: "SmartSentinel", subtitle: "对象 / 字典 / 数组 / 并发",
                          make: { SmartSentinelDemoViewController() }),
            ]),
            DemoSection(title: "4. 案例", items: [
                DemoEntry(title: "自定义 Codable", subtitle: "自定义 init(from:) / encode(to:)",
                          make: { CustomCodableDemoViewController() }),
                DemoEntry(title: "多 Key 映射", subtitle: "一字段对应多个 JSON key",
                          make: { MultiKeyMappingDemoViewController() }),
                DemoEntry(title: "范型解析", subtitle: "ApiCommon<T: SmartCodableX>",
                          make: { GenericDecodeDemoViewController() }),
                DemoEntry(title: "单值容器", subtitle: "SingleValueContainer 解析",
                          make: { SingleValueDemoViewController() }),
                DemoEntry(title: "多态分发", subtitle: "根据 type 字段分发到不同模型",
                          make: { TypeDispatchDemoViewController() }),
            ]),
            DemoSection(title: "5. 属性包装器", items: [
                DemoEntry(title: "@SmartFlat", subtitle: "扁平化嵌套 JSON",
                          make: { SmartFlatDemoViewController() }),
                DemoEntry(title: "@SmartAny", subtitle: "Any / [Any] / [String: Any]",
                          make: { SmartAnyDemoViewController() }),
                DemoEntry(title: "@SmartIgnored", subtitle: "排除字段不参与编解码",
                          make: { SmartIgnoredDemoViewController() }),
                DemoEntry(title: "@SmartPublished", subtitle: "SwiftUI / Combine 集成",
                          make: { SmartPublishedDemoViewController() }),
            ]),
            DemoSection(title: "6. 枚举", items: [
                DemoEntry(title: "枚举解析", subtitle: "SmartCaseDefaultable / SmartAssociatedEnumerable",
                          make: { EnumDecodeDemoViewController() }),
            ]),
            DemoSection(title: "7. 其它", items: [
                DemoEntry(title: "继承能力（@SmartSubclass）", subtitle: "已迁移到 SmartCodableMacro 仓库",
                          make: { InheritanceLinkViewController() }),
                DemoEntry(title: "测试沙盒", subtitle: "一个空白页面，方便临时测试",
                          make: { TestViewController() }),
            ]),
        ]
    }
}
