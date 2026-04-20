<p align="center">
<img src="https://github.com/intsig171/SmartCodable/assets/87351449/89de27ac-1760-42ee-a680-4811a043c8b1" alt="SmartCodable" title="SmartCodable" width="500"/>
</p>
<h1 align="center">SmartCodable - Resilient & Flexible Codable for Swift</h1>

<p align="center">
<a href="https://github.com/iAmMccc/SmartCodable/releases">
    <img src="https://img.shields.io/github/v/release/iAmMccc/SmartCodable?color=blue&label=version" alt="Latest Release">
</a>
<a href="https://swift.org/">
    <img src="https://img.shields.io/badge/Swift-5.0%2B-orange.svg" alt="Swift 5.0+">
</a>
<a href="https://github.com/iAmMccc/SmartCodable/wiki">
    <img src="https://img.shields.io/badge/Documentation-available-brightgreen.svg" alt="Documentation">
</a>
<a href="https://swift.org/package-manager/">
    <img src="https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat" alt="SPM Supported">
</a>
<a href="https://github.com/iAmMccc/SmartCodable/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-black.svg" alt="MIT License">
</a>
<a href="https://deepwiki.com/intsig171/SmartCodable">
    <img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki">
</a>
</p>


English | [中文](README_CN.md)

**SmartCodable** enhances Apple's native Codable with production-ready resilience. When standard Codable fails on a single missing field or type mismatch, your entire model is lost. SmartCodable gracefully recovers — falling back to defaults, converting types automatically, and never interrupting the parse.

## Why SmartCodable?

| Scenario | Standard Codable | SmartCodable |
|:---------|:----------------|:-------------|
| Missing key | ❌ Throws `keyNotFound`, entire model fails | ✅ Uses property initializer as default |
| Type mismatch (e.g., `"123"` for `Int`) | ❌ Throws `typeMismatch`, entire model fails | ✅ Auto-converts, returns `123` |
| Null value for non-optional | ❌ Throws `valueNotFound`, entire model fails | ✅ Falls back to default value |
| Extra unknown keys | ✅ Ignored | ✅ Ignored |

**vs HandyJSON**: SmartCodable builds on Apple's Codable protocol — no unsafe runtime reflection, no ABI stability risks. HandyJSON relies on Swift metadata reflection that may break across Swift versions.

**vs Manual `init(from:)`**: SmartCodable eliminates the boilerplate of writing `decodeIfPresent` + `??` for every property. Same safety, zero ceremony.



## Quick Start

```swift
import SmartCodable

struct User: SmartCodableX {
    var name: String = ""
    var age: Int = 0
}

// ✅ Normal case
let user = User.deserialize(from: ["name": "John", "age": 30])
// User(name: "John", age: 30)

// ✅ Missing field — falls back to default
let user2 = User.deserialize(from: ["name": "John"])
// User(name: "John", age: 0)

// ✅ Type mismatch — auto-converts
let user3 = User.deserialize(from: ["name": "John", "age": "30"])
// User(name: "John", age: 30)
```

For struct, the compiler provides a default empty initializer. For class, you need `required init() {}`.



## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/iAmMccc/SmartCodable.git", from: "xxx")
]
```

- `SmartCodable` (core) works without Swift Macros.
- `SmartCodableInherit` (inheritance via `@SmartSubclass`) requires **Xcode 15+** and **Swift 5.9+**.

### CocoaPods

| Version     | Installation                 | Requirements |
|:------------|:-----------------------------|:-------------|
| Basic       | `pod 'SmartCodable'`         | iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+ |
| Inheritance | `pod 'SmartCodable/Inherit'` | iOS 13+, macOS 11+, Xcode 15+, Swift 5.9+ |

> ⚠️ The Inheritance pod depends on `swift-syntax`, which may take longer on first build.



## Features

### 1. Deserialization

Supports multiple input formats:

```swift
// From Dictionary
let model = Model.deserialize(from: dict)

// From JSON String
let model = Model.deserialize(from: jsonString)

// From Data
let model = Model.deserialize(from: data)

// Array
let models = [Model].deserialize(from: array)
```

**Deep Path Navigation** — Extract nested data directly:

```swift
// JSON: {"data": {"user": {"info": { ... }}}}
let model = Model.deserialize(from: json, designatedPath: "data.user.info")
```

**Decoding Strategies:**

```swift
let options: Set<SmartDecodingOption> = [
    .key(.convertFromSnakeCase),
    .date(.iso8601),
    .data(.base64)
]
let model = Model.deserialize(from: json, options: options)
```

### 2. Key Mapping

Map JSON keys to Swift property names. First non-null match wins:

```swift
static func mappingForKey() -> [SmartKeyTransformer]? {
    [
        CodingKeys.id <--- ["user_id", "userId", "id"],
        CodingKeys.name <--- "nested.path.to.name"   // nested path supported
    ]
}
```

### 3. Value Transformation

Convert between JSON values and custom types:

```swift
static func mappingForValue() -> [SmartValueTransformer]? {
    [
        CodingKeys.url <--- SmartURLTransformer(prefix: "https://"),
        CodingKeys.date <--- SmartDateFormatTransformer(DateFormatter()),
        CodingKeys.status <--- FastTransformer<Status, String>(
            fromJSON: { Status(rawValue: $0 ?? "") },
            toJSON: { $0?.rawValue }
        ),
    ]
}
```

**Built-in Transformers:**

| Transformer | JSON → Object |
|:------------|:-------------|
| `SmartDateTransformer` | Double/String → Date |
| `SmartDateFormatTransformer` | String (custom format) → Date |
| `SmartDataTransformer` | Base64 String → Data |
| `SmartURLTransformer` | String → URL (with optional prefix & encoding) |
| `SmartHexColorTransformer` | Hex String → UIColor/NSColor |

Need custom logic? Implement `ValueTransformable`:

```swift
public protocol ValueTransformable {
    associatedtype Object
    associatedtype JSON
    func transformFromJSON(_ value: Any?) -> Object?
    func transformToJSON(_ value: Object?) -> JSON?
}
```

### 4. Property Wrappers

| Wrapper | Purpose | Example |
|:--------|:--------|:--------|
| `@SmartAny` | `Any`, `[Any]`, `[String: Any]` support | `@SmartAny var dict: [String: Any] = [:]` |
| `@SmartIgnored` | Skip property during decoding | `@SmartIgnored var cache: String = ""` |
| `@SmartFlat` | Flatten nested object into parent | `@SmartFlat var profile: Profile?` |
| `@SmartPublished` | Combine `ObservableObject` support | `@SmartPublished var name: String?` |
| `@SmartHexColor` | Hex string → UIColor/NSColor | `@SmartHexColor var color: UIColor?` |
| `@SmartDate` | Multi-format date parsing | `@SmartDate var date: Date?` |
| `@SmartCompact.Array` | Skip invalid array elements | `@SmartCompact.Array var ids: [Int]` |
| `@SmartCompact.Dictionary` | Skip invalid dict entries | `@SmartCompact.Dictionary var info: [String: String]` |

**@SmartFlat example** — flatten nested fields into parent:

```swift
struct Model: SmartCodableX {
    var name: String = ""
    @SmartFlat var profile: Profile?
}
struct Profile: SmartCodableX {
    var name: String = ""
    var age: Int = 0
}

// JSON: {"name": "Mccc", "age": 18}
// profile gets name="Mccc", age=18 from the SAME level
```

**@SmartCompact.Array example** — tolerant array parsing:

```swift
struct Model: Decodable {
    @SmartCompact.Array var ages: [Int]
}

// JSON: {"ages": ["Tom", 1, {}, 2, 3, "4"]}
// Result: ages = [1, 2, 3, 4]  (invalid elements skipped, "4" auto-converted)
```

### 5. Inheritance

Annotate subclasses with `@SmartSubclass` (requires Swift 5.9+):

```swift
class BaseModel: SmartCodableX {
    var name: String = ""
    required init() {}
}

@SmartSubclass
class StudentModel: BaseModel {
    var age: Int = 0
}
```

The macro generates `CodingKeys`, `init(from:)`, and `encode(to:)` automatically. See [Inheritance Guide](https://github.com/iAmMccc/SmartCodable/blob/main/Document/QA/QA2.md) for advanced usage (protocol methods in parent/subclass).

### 6. Enum Support

**Simple enums** — conform to `SmartCaseDefaultable`:

```swift
enum Sex: String, SmartCaseDefaultable {
    case man
    case woman
}
```

**Enums with associated values** — conform to `SmartAssociatedEnumerable` + provide a transformer:

```swift
enum Sex: SmartAssociatedEnumerable {
    case man, woman, other(String)
}

// In model's mappingForValue(), provide a custom transformer
```

### 7. Post-Processing & Update

**`didFinishMapping()`** — runs after decoding completes:

```swift
struct Model: SmartCodableX {
    var name: String = ""
    mutating func didFinishMapping() {
        name = "I am \(name)"
    }
}
```

**`SmartUpdater`** — update an existing model with new data:

```swift
var model = Model.deserialize(from: initialData)!
SmartUpdater.update(&model, from: newData)
```

### 8. Stringified JSON

SmartCodable auto-detects and parses string-encoded JSON:

```swift
struct Model: SmartCodableX {
    var hobby: Hobby?
}
// JSON: {"hobby": "{\"name\":\"sleep\"}"}
// hobby is parsed as Hobby(name: "sleep"), not a raw string
```

### 9. Debugging

```swift
SmartSentinel.debugMode = .verbose  // .none | .verbose | .alert
SmartSentinel.onLogGenerated { log in print(log) }
```

```
================================  [Smart Sentinel]  ================================
UserModel 👈🏻 👀
╆━ UserModel
┆┄ age    : Expected Int, got String — auto-converted
┆┄ email  : Key not found — using default ""
====================================================================================
```



## Explore & Contribute

| | |
|:--|:--|
| 🔧 [Migrate from HandyJSON](https://github.com/iAmMccc/SmartCodable/blob/main/Explore%26Contribute/CompareWithHandyJSON.md) | Step-by-step migration guide |
| 🛠 [SmartModeler](https://github.com/iAmMccc/SmartModeler) | JSON → SmartCodable model generator |
| 👀 [SmartSentinel](https://github.com/iAmMccc/SmartCodable/blob/main/Explore%26Contribute/Sentinel.md) | Real-time parsing log viewer |
| 💖 [Contributing](https://github.com/iAmMccc/SmartCodable/blob/main/Explore%26Contribute/Contributing.md) | Support SmartCodable development |
| 🏆 [Contributors](https://github.com/iAmMccc/SmartCodable/blob/main/Explore%26Contribute/Contributors.md) | Key contributors |

## FAQ

- [👉 Learn more about SmartCodable](https://github.com/iAmMccc/SmartCodable/blob/main/Document/Usages/LearnMore.md)
- [👉 GitHub Discussions](https://github.com/iAmMccc/SmartCodable/discussions)
- [👉 How to Test](https://github.com/iAmMccc/SmartCodable/blob/main/Document/Usages/HowToTest.md)



## GitHub Stars

<p style="margin:0">
  <img src="https://starchart.cc/iAmMccc/SmartCodable.svg" alt="Stars" width="750">
</p>



## Join Community 🚀

SmartCodable is an open-source project dedicated to making Swift data parsing more robust, flexible and efficient. We welcome all developers to join our community!

<p>
  <img src="https://github.com/user-attachments/assets/7b1f8108-968e-4a38-91dd-b99abdd3e500" alt="JoinUs" width="700">
</p>
