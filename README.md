<p align="center">
<img src="https://github.com/intsig171/SmartCodable/assets/87351449/89de27ac-1760-42ee-a680-4811a043c8b1" alt="SmartCodable" title="SmartCodable" width="500"/>
</p>
<h1 align="center">SmartCodable - Ultimate Codable Enhancement for Swift</h1>

<p align="center">
<a href="https://github.com/iAmMccc/SmartCodable/releases">
    <img src="https://img.shields.io/github/v/release/iAmMccc/SmartCodable?color=blue&label=version" alt="Latest Release">
</a>
<a href="https://github.com/iAmMccc/SmartCodable/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/iAmMccc/SmartCodable/swift.yml?branch=main&label=build%20status&logo=github" alt="Build Status">
</a>
<a href="https://github.com/iAmMccc/SmartCodable/wiki">
    <img src="https://img.shields.io/badge/Documentation-available-brightgreen.svg" alt="Documentation">
</a>
<a href="https://swift.org/package-manager/">
    <img src="https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat" alt="SPM Supported">
</a>
<a href="https://swift.org/">
    <img src="https://img.shields.io/badge/Swift-5.0%2B-orange.svg" alt="Swift 5.0+">
</a>
</p>


<p align="center">
<a href="https://www.apple.com/swift/">
    <img src="https://img.shields.io/badge/platform-iOS%2FmacOS%2FtvOS%2FwatchOS-blue.svg" alt="Platform Support">
</a>
<a href="https://github.com/iAmMccc/SmartCodable/graphs/contributors">
    <img src="https://img.shields.io/github/contributors/iAmMccc/SmartCodable" alt="Contributors">
</a>
<a href="https://github.com/iAmMccc/SmartCodable/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-black.svg" alt="MIT License">
</a>
<a href="https://deepwiki.com/intsig171/SmartCodable">
    <img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki">
</a>
</p>


### English | [中文](https://github.com/iAmMccc/SmartCodable/blob/main/README_CN.md)



SmartCodable redefines Swift data parsing by augmenting Apple's native Codable with production-ready resilience and flexibility. Where standard Codable fails on real-world data, SmartCodable delivers bulletproof parsing with minimal boilerplate.

## **SmartCodable vs Codable**

| 🎯 Feature                  | 💬 Description                                                |
| :------------------------- | :----------------------------------------------------------- |
| **Error Tolerance**        | Military-grade handling of type mismatches, null values, and missing keys |
| **Type Adaptation**        | Automatic bidirectional type conversion (String⇄Number, Number⇄Bool, etc.) |
| **Default Value Fallback** | Falls back to property initializers when parsing fails       |
| **Support inheritance**    | Barrier-free support for inheritance                         |
| **Key Mapping**            | Multi-source key mapping with priority system                |
| **Value Transformation**   | Custom value transformers                                    |
| **Collection Safety**      | Safe collection handling (empty arrays→nil, invalid elements→filtered) |
| **Deep Modelization**      | Recursive modelization of nested JSON structures             |
| **Dynamic Types**          | Full support for `Any`, `[Any]`, `[String:Any]` via `@SmartAny` |
| **Naming Strategies**      | Global key strategies (snake_case⇄camelCase, capitalization) |
| **Lifecycle Hooks**        | `didFinishMapping()` callback for post-processing            |
| **Incremental Updates**    | Partial model updates without full re-parsing                |
| **Property Wrappers**      | such as`@IgnoredKey`, `@SmartFlat`,`@SmartAny`               |
| **Debugging Support**      | Built-in logging with path tracing for decoding errors       |
| **Path Navigation**        | Deep JSON access using dot notation (`designatedPath: "data.user"`) |
| **PropertyList Support**   | Native support for parsing PropertyList data without JSON conversion |
| **Parsing Diagnostics**    | Real-time monitoring with `SmartSentinel.monitorLogs()`      |



## SmartCodable vs HandyJSON 

| 🎯 Feature                              | 💬 Description                                                | SmartCodable | HandyJSON |
| :------------------------------------- | :----------------------------------------------------------- | :----------- | :-------- |
| **Strong Compatibility**               | Perfectly handles: **Missing fields** & **Null values** & **Type mismatches** | ✅            | ✅         |
| **Type Adaptation**                    | Automatic conversion between types (e.g., JSON Int to Model String) | ✅            | ✅         |
| **Any Parsing**                        | Supports parsing **[Any], [String: Any]** types              | ✅            | ✅         |
| **Decoding Callback**                  | Provides **didFinishingMapping** callback when model decoding completes | ✅            | ✅         |
| **Default Value Initialization**       | Uses property's initial value when parsing fails             | ✅            | ✅         |
| **String-to-Model Parsing**            | Supports parsing JSON strings into models                    | ✅            | ✅         |
| **Enum Parsing**                       | Provides fallback for failed enum parsing                    | ✅            | ✅         |
| **Custom Property Parsing - Renaming** | Custom decoding keys (renaming model properties)             | ✅            | ✅         |
| **Custom Property Parsing - Ignoring** | Ignores specific model properties during decoding            | ✅            | ✅         |
| **designatedPath Support**             | Custom parsing paths                                         | ✅            | ✅         |
| **Model Inheritance**                  | Use `@SmartSubclass` to modify the Model                     | ✅            | ✅         |
| **Custom Parsing Paths**               | Specifies starting JSON hierarchy level for parsing          | ✅            | ✅         |
| **Complex Data Decoding**              | Advanced data processing during decoding (e.g., data flattening) | ✅            | ⚠️         |
| **Decoding Performance**               | SmartCodable averages 20% better performance                 | ✅            | ⚠️         |
| **Error Logging**                      | Provides troubleshooting logs for compatibility handling     | ✅            | ❌         |
| **Security**                           | Implementation stability and security                        | ✅            | ❌         |

If you are using HandyJSON and would like to replace it, follow this link.

 [👉 **SmartCodable - Compare With HandyJSON**](https://github.com/iAmMccc/SmartCodable/blob/main/Document/README/CompareWithHandyJSON.md)

**Key Advantages**:

- 20% better performance
- More stable and secure implementation
- Built-in error diagnostics
- Superior complex data handling



## SmartCodable Supported Types Comparison

| Type               | Examples                              |
| :----------------- | :------------------------------------ |
| **Integer**        | `Int`, `Int8-64`, `UInt`, `UInt8-64`  |
| **Floating Point** | `Float`, `Double`, `CGFloat`          |
| **Boolean**        | `Bool` (accepts `true`/`1`/`"true"`)  |
| **String**         | `String` (auto-converts from numbers) |
| **Foundation**     | `URL`, `Date`, `Data`, `UIColor`      |
| **Enums**          | All `RawRepresentable` enums          |
| **Collections**    | `[String: Codable]`, `[Codable]`      |
| **Nested Models**  | Any `Codable` custom types            |
| **Wrappers**       | `@SmartAny`, `@IgnoredKey`, etc.      |

## Installation

### 🛠 CocoaPods Installation

| Version     | Installation Method          | Platform Requirements                                        |
| :---------- | :--------------------------- | :----------------------------------------------------------- |
| Basic       | `pod 'SmartCodable'`         | `iOS 12+` `tvOS 12+` `macOS 10.13+` `watchOS 5.0+` `visionOS 1.0+` |
| Inheritance | `pod 'SmartCodable/Inherit'` | `iOS 13+` `macOS 11+`                                        |

⚠️ **Important Notes**:

- If you don't have strong inheritance requirements, the basic version is recommended

- Inheritance features require **Swift Macro support**, **Xcode 15+**, and **Swift 5.9+**

  

  

📌 **About Swift Macros Support (CocoaPods)**:

* requires downloading `swift-syntax` dependencies for the first time (may take longer)
* CocoaPods internally sets `user_target_xcconfig["OTHER_SWIFT_FLAGS"]` to load the macro plugin during build.
* This may affect your main target's build flags and lead to subtle differences in complex projects or CI environments.
* If needed, please [open an issue](https://github.com/iAmMccc/SmartCodable/issues) for custom setups.



### 📦 Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/iAmMccc/SmartCodable.git", from: "xxx")
]
```



### Usage Examples

```swift
import SmartCodable

struct User: SmartCodable {
    var name: String = ""
    var age: Int = 0
}
let user = User.deserialize(from: ["name": "John", "age": 30])
```



# Deserialization

To support deserialization from JSON, a class/struct need to conform to 'SmartCodable' protocol. 

### 1. The Basics

To conform to 'SmartCodable', a class need to implement an empty initializer.

```swift
class BasicTypes: SmartCodable {
    var int: Int = 2
    var doubleOptional: Double?
    required init() {}
}
let model = BasicTypes.deserialize(from: json)
```

For struct, since the compiler provide a default empty initializer, we use it for free.

```swift
struct BasicTypes: SmartCodable {
    var int: Int = 2
    var doubleOptional: Double?
}
let model = BasicTypes.deserialize(from: json)
```



### 2. Deserialization API

#### 2.1 deserialize

Only types conforming to `SmartCodable` (or `[SmartCodable]` for arrays) can use these methods

```swift
public static func deserialize(from dict: [String: Any]?, designatedPath: String? = nil,  options: Set<SmartDecodingOption>? = nil) -> Self?

public static func deserialize(from json: String?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self?

public static func deserialize(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self?

public static func deserializePlist(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self?
```

**1. Multi-Format Input Support**

| Input Type       | Example Usage                          | Internal Conversion                   |
| :--------------- | :------------------------------------- | :------------------------------------ |
| Dictionary/Array | `Model.deserialize(from: dict or arr)` | Directly processes native collections |
| JSON String      | `Model.deserialize(from: jsonString)`  | Converts to `Data` via UTF-8          |
| Binary Data      | `Model.deserialize(from: data)`        | Processes directly                    |

**2. Deep Path Navigation (`designatedPath`)**

```
// JSON Structure:
{
  "data": {
    "user": {
      "info": { ...target content... }
    }
  }
}

// Access nested data:
Model.deserialize(from: json, designatedPath: "data.user.info")
```

**Path Resolution Rules:**

1. Dot-separated path components
2. Handles both dictionaries and arrays
3. Returns `nil` if any path segment is invalid
4. Empty path returns entire content

**3. Decoding Strategies (`options`)**

```swift
let options: Set<SmartDecodingOption> = [
    .key(.convertFromSnakeCase),
    .date(.iso8601),
    .data(.base64)
]
```

| Strategy Type      | Available Options                     | Description                  |
| :----------------- | :------------------------------------ | :--------------------------- |
| **Key Decoding**   | `.fromSnakeCase`                      | snake_case → camelCase       |
|                    | `.firstLetterLower`                   | "FirstName" → "firstName"    |
|                    | `.firstLetterUpper`                   | "firstName" → "FirstName"    |
| **Date Decoding**  | `.iso8601`, `.secondsSince1970`, etc. | Full Codable date strategies |
| **Data Decoding**  | `.base64`                             | Binary data processing       |
| **Float Decoding** | `.convertToString`, `.throw`          | NaN/∞ handling               |

> ⚠️ **Important**: Only one strategy per type is allowed (last one wins if duplicates exist)



#### 2.2 Post-processing callback invoked after successful decoding

```swift
struct Model: SmartCodable {
    var name: String = ""
    
    mutating func didFinishMapping() {
        name = "I am \(name)"
    }
}
```



#### 3.2 Key Transformation

Defines key mapping transformations during decoding，First non-null mapping is preferred。

```swift
static func mappingForKey() -> [SmartKeyTransformer]? {
    return [
        CodingKeys.id <--- ["user_id", "userId", "id"],
        CodingKeys.joinDate <--- "joined_at"
    ]
}
```



#### 4.3 **Value Transformation**

Convert between JSON values and custom types

**Built-in Value Transformers**

| Transformer                    | JSON Type     | Object Type | Description                                                  |
| :----------------------------- | :------------ | :---------- | :----------------------------------------------------------- |
| **SmartDataTransformer**       | String        | Data        | Converts between Base64 strings and Data objects             |
| **SmartHexColorTransformer**   | String        | ColorObject | Converts hex color strings to platform-specific color objects (UIColor/NSColor) |
| **SmartDateTransformer**       | Double/String | Date        | Handles multiple date formats (timestamp Double or String) to Date objects |
| **SmartDateFormatTransformer** | String        | Date        | Uses DateFormatter for custom date string formats            |
| **SmartURLTransformer**        | String        | URL         | Converts strings to URLs with optional encoding and prefixing |

```swift
struct Model: SmartCodable {
    
    ...
    
    static func mappingForValue() -> [SmartValueTransformer]? {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        return [
            CodingKeys.url <--- SmartURLTransformer(prefix: "https://"),
            CodingKeys.date2 <--- SmartDateTransformer(),
            CodingKeys.date1 <--- SmartDateFormatTransformer(format)
        ]
    }
}
```

If you need additional parsing rules, **Transformer** will implement them yourself. Follow **ValueTransformable** to implement the requirements of the protocol.

```swift
public protocol ValueTransformable {
    associatedtype Object
    associatedtype JSON
    
    /// transform from ’json‘ to ’object‘
    func transformFromJSON(_ value: Any?) -> Object?
    
    /// transform to ‘json’ from ‘object’
    func transformToJSON(_ value: Object?) -> JSON?
}
```

**Built-in Fast Transformer Helper**

```swift
static func mappingForValue() -> [SmartValueTransformer]? {
    [
        CodingKeys.name <--- FastTransformer<String, String>(fromJSON: { json in
            "abc"
        }, toJSON: { object in
            "123"
        }),
        CodingKeys.subModel <--- FastTransformer<TestEnum, String>(fromJSON: { json in
            TestEnum.man
        }, toJSON: { object in
            object?.rawValue
        }),
    ]
}
```






### 3. propertyWrapper

#### 3.1 @SmartAny

Codable does not support Any resolution, but can be implemented using @SmartAny。

```swift
struct Model: SmartCodable {
    @SmartAny var dict: [String: Any] = [:]
    @SmartAny var arr: [Any] = []
    @SmartAny var any: Any?
}
let dict: [String: Any] = [
    "dict": ["name": "Lisa"],
    "arr": [1,2,3],
    "any": "Mccc"
]

let model = Model.deserialize(from: dict)
print(model)
// Model(dict: ["name": "Lisa"], arr: [1, 2, 3], any: "Mccc")
```



#### 3.2 @IgnoredKey

If you need to ignore the parsing of attributes, you can override `CodingKeys` or use `@IgnoredKey`.

```swift
struct Model: SmartCodable {
    @IgnoredKey
    var name: String = ""
}

let dict: [String: Any] = [
    "name": "Mccc"
]

let model = Model.deserialize(from: dict)
print(model)
// Model(name: "")
```



#### 3.3 @SmartFlat

```swift
struct Model: SmartCodable {
    var name: String = ""
    var age: Int = 0
  
    @SmartFlat
    var model: FlatModel?
   
}
struct FlatModel: SmartCodable {
    var name: String = ""
    var age: Int = 0
}

let dict: [String: Any] =  [
    "name": "Mccc",
    "age": 18,
]

let model = Model.deserialize(from: dict)
print(model)
// Model(name: "Mccc", age: 18, model: FlatModel(name: "Mccc", age: 18))
```



#### 3.4 @SmartPublished

```swift
class PublishedModel: ObservableObject, SmartCodable {
    required init() {}
    
    @SmartPublished
    var name: ABC?
}

struct ABC: SmartCodable {
    var a: String = ""
}

if let model = PublishedModel.deserialize(from: dict) {
    model.$name
        .sink { newName in
            print("name updated，newValue is: \(newName)")
        }
        .store(in: &cancellables)
}
```

#### 3.5 @SmartHexColor

Adds Codable support for UIColor/NSColor using hex string encoding/decoding.

```swift
struct Model: SmartCodable {
    @SmartHexColor
    var color: UIColor?
}

let dict: [String: Any] = [
    "color": "7DA5E3"
]

let model = Model.deserialize(from: dict)
print(model)
// print: Model(color: UIExtendedSRGBColorSpace 0.490196 0.647059 0.890196 1)
```



### 4. Inheritance Support

This feature relies on **Swift Macros**, which requires **Swift 5.9+** and is compatible with **iOS 13+**. Therefore, it is only supported in SmartCodable version 5.0 and above.

> For using inheritance on lower versions, refer to: [Inheritance in Lower Versions](https://github.com/iAmMccc/SmartCodable/blob/main/Document/QA/QA2.md)

If you need inheritance support, annotate your subclass with `@SmartSubclass`.

#### 4.1 Basic Usage

```swift
class BaseModel: SmartCodable {
    var name: String = ""
    required init() { }
}

@SmartSubclass
class StudentModel: BaseModel {
    var age: Int?
}
```

#### 4.2 Subclass Implements Protocol Method

Just implement it directly—no need for the `override` keyword.

```swift
class BaseModel: SmartCodable {
    var name: String = ""
    required init() { }
    
    class func mappingForKey() -> [SmartKeyTransformer]? {
        retrun nil
    }
}

@SmartSubclass
class StudentModel: BaseModel {
    var age: Int?
    
    override static func mappingForKey() -> [SmartKeyTransformer]? {
        [ CodingKeys.age <--- "stu_age" ]
    }
}
```

#### 4.3 Parent Class Implements Protocol Method

```swift
class BaseModel: SmartCodable {
    var name: String = ""
    required init() { }
    
    static func mappingForKey() -> [SmartKeyTransformer]? {
        [ CodingKeys.name <--- "stu_name" ]
    }
}

@SmartSubclass
class StudentModel: BaseModel {
    var age: Int?
}
```

#### 4.4 Both Parent and Subclass Implement Protocol Method

A few things to note:

- The protocol method in the parent class must be marked with `class`.
- The subclass should call the parent class's implementation.

```swift
class BaseModel: SmartCodable {
    var name: String = ""
    required init() { }
    
    class func mappingForKey() -> [SmartKeyTransformer]? {
        [ CodingKeys.name <--- "stu_name" ]
    }
}

@SmartSubclass
class StudentModel: BaseModel {
    var age: Int?
    
    override static func mappingForKey() -> [SmartKeyTransformer]? {
        let trans = [ CodingKeys.age <--- "stu_age" ]
        
        if let superTrans = super.mappingForKey() {
            return trans + superTrans
        } else {
            return trans
        }
    }
}
```



### 5. Special support

#### 5.1 Smart Stringified JSON Parsing

SmartCodable automatically handles string-encoded JSON values during decoding, seamlessly converting them into nested model objects or arrays while maintaining all key mapping rules.

- **Automatic Parsing**: Detects and decodes stringified JSON (`"{\"key\":value}"`) into proper objects/arrays
- **Recursive Mapping**: Applies `mappingForKey()` rules to parsed nested structures
- **Type Inference**: Determines parsing strategy (object/array) based on property type

```swift
struct Model: SmartCodable {
    var hobby: Hobby?
    var hobbys: [Hobby]?
}

struct Hobby: SmartCodable {
    var name: String = ""
}

let dict: [String: Any] = [
    "hobby": "{\"name\":\"sleep1\"}",
    "hobbys": "[{\"name\":\"sleep2\"}]",
]

guard let model = Model.deserialize(from: dict) else { return }
```



#### 5.2 Compatibility

If attribute resolution fails, SmartCodable performs compatibility processing for thrown exceptions. Ensure that the entire parsing is not interrupted. Even better, you don't have to do anything about it.

```swift
let dict = [
    "number1": "123",
    "number2": "Mccc",
    "number3": "Mccc"
]

struct Model: SmartCodable {
    var number1: Int?
    var number2: Int?
    var number3: Int = 1
}

// decode result
// Model(number1: 123, number2: nil, number3: 1)
```

**Type conversion compatibility**

When the data is parsed, the type cannot be matched. Raises a.typeMismatch error. SmartCodable will attempt to convert data of type String to the desired type Int.

**Default Fill compatible**

When the type conversion fails, the initialization value of the currently parsed property is retrieved for padding.

#### 5.3 parse very large data

When you parse very large data, try to avoid the compatibility of parsing exceptions, such as: more than one attribute is declared in the attribute, and the declared attribute type does not match. 

Do not use @IgnoredKey when there are attributes that do not need to be parsed, override CodingKeys to ignore unwanted attribute parsing. 

This can greatly improve the analytical efficiency.



#### 5.4 The Enum

To be convertable, An `enum` must conform to `SmartCaseDefaultable` protocol. Nothing special need to do now.

```swift
struct Student: SmartCodable {
    var name: String = ""
    var sex: Sex = .man

    enum Sex: String, SmartCaseDefaultable {
        case man = "man"
        case woman = "woman"
    }
}
let model = Student.deserialize(from: json)
```



**Decoding of associative value enum**

Make the enumeration follow **SmartAssociatedEnumerable**。Override the **mappingForValue** method and take over the decoding process yourself.

```swift
struct Model: SmartCodable {
    var sex: Sex = .man
    static func mappingForValue() -> [SmartValueTransformer]? {
        [
            CodingKeys.sex <--- RelationEnumTranformer()
        ]
    }
}

enum Sex: SmartAssociatedEnumerable {    
    case man
    case women
    case other(String)
}

struct RelationEnumTranformer: ValueTransformable {
    typealias Object = Sex
    typealias JSON = String

    func transformToJSON(_ value: Introduce_8ViewController.Sex?) -> String? {
        // do something
    }
    func transformFromJSON(_ value: Any?) -> Sex? {
        // do something
    }
}
```



#### 5.5 Update Existing Model

It can accommodate any data structure, including nested array structures.

```swift
struct Model: SmartCodable {
    var name: String = ""
    var age: Int = 0
}

var dic1: [String : Any] = [
    "name": "mccc",
    "age": 10
]
let dic2: [String : Any] = [
    "age": 200
]
guard var model = Model.deserialize(from: dic1) else { return }
SmartUpdater.update(&model, from: dic2)

// now: model is ["name": mccc, "age": 200].
```





## **Sentinel** 

SmartCodable is integrated with Smart Sentinel, which listens to the entire parsing process. After the parsing is complete, formatted log information is displayed. 

This information is used only as auxiliary information to help you discover and rectify problems. This does not mean that the parsing failed.

```
================================  [Smart Sentinel]  ================================
Array<SomeModel> 👈🏻 👀
   ╆━ Index 0
      ┆┄ a: Expected to decode 'Int' but found ‘String’ instead.
      ┆┄ b: Expected to decode 'Int' but found ’Array‘ instead.
      ┆┄ c: No value associated with key.
      ╆━ sub: SubModel
         ┆┄ sub_a: No value associated with key.
         ┆┄ sub_b: No value associated with key.
         ┆┄ sub_c: No value associated with key.
      ╆━ sub2s: [SubTwoModel]
         ╆━ Index 0
            ┆┄ sub2_a: No value associated with key.
            ┆┄ sub2_b: No value associated with key.
            ┆┄ sub2_c: No value associated with key.
         ╆━ Index 1
            ┆┄ sub2_a: Expected to decode 'Int' but found ’Array‘ instead.
   ╆━ Index 1
      ┆┄ a: No value associated with key.
      ┆┄ b: Expected to decode 'Int' but found ‘String’ instead.
      ┆┄ c: Expected to decode 'Int' but found ’Array‘ instead.
      ╆━ sub: SubModel
         ┆┄ sub_a: Expected to decode 'Int' but found ‘String’ instead.
      ╆━ sub2s: [SubTwoModel]
         ╆━ Index 0
            ┆┄ sub2_a: Expected to decode 'Int' but found ‘String’ instead.
         ╆━ Index 1
            ┆┄ sub2_a: Expected to decode 'Int' but found 'null' instead.
====================================================================================
```

If you want to use it, turn it on:

```swift
SmartSentinel.debugMode = .verbose
public enum Level: Int {
    case none
    case verbose
    case alert
}
```

If you want to get this log to upload to the server:

```swift
SmartSentinel.onLogGenerated { logs in  }
```


## SmartModeler - JSON To Swift SmartCodable Tool

[online access](https://iammccc.github.io)
![](https://github.com/iAmMccc/iAmMccc.github.io/blob/main/演示图.png)


## FAQ

If you're looking forward to learning more about the Codable protocol and the design thinking behind SmartCodable, check it out.

[👉 **github discussions**](https://github.com/iAmMccc/SmartCodable/discussions)

[👉 **SmartCodable Test**](https://github.com/iAmMccc/SmartCodable/blob/main/Document/README/HowToTest.md)

[👉 **learn SmartCodable**](https://github.com/iAmMccc/SmartCodable/blob/main/Document/README/LearnMore.md)



## Github Stars
![GitHub stars](https://starchart.cc/iAmMccc/SmartCodable.svg)

## Join the SmartCodable Community 🚀

SmartCodable is an open-source project dedicated to making Swift data parsing more robust, flexible and efficient. We welcome all developers to join our community!


![JoinUs](https://github.com/user-attachments/assets/7b1f8108-968e-4a38-91dd-b99abdd3e500)



## Support 💖

![Support](https://github.com/iAmMccc/SmartCodable/blob/main/Document/support.png)



## License

SmartCodable is available under the MIT license. See the LICENSE file for more info.

