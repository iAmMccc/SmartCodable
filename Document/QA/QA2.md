# QA2 支持继承关系的解析

## 推荐方案：@SmartSubclass（SmartCodable 5.0+）

从 SmartCodable 5.0 开始，推荐使用 `@SmartSubclass` 宏处理继承。这是最简洁的方案，宏会在编译期自动生成 `CodingKeys`、`init(from:)` 和 `encode(to:)`：

```swift
class BaseModel: SmartCodable {
    var name: String = ""
    required init() { }
}

@SmartSubclass
class Model: BaseModel {
    var age: Int = 0
}

let dict = ["name": "小明", "age": 10] as [String : Any]
guard let model = Model.deserialize(from: dict) else { return }
print(model.age)   // 10
print(model.name)  // 小明
```

> ⚠️ 需要 **Swift 5.9+** 和 **Xcode 15+**。如果使用低版本，请参考下方的替代方案。

---

以下是低版本或特殊场景下的替代方案。

## HandyJSON 如何处理继承的解析

`HandyJSON` 能自动处理继承层级中的所有属性，子类无需额外实现任何方法，使用方式非常简洁，示例如下：

```
class BaseModel: HandyJSON {
    var name: String = ""
    required init() { }
}

class Model: BaseModel {
    var age: Int = 0
}

let dict = [
    "name": "小明",
    "age": 10
] as [String : Any]

guard let model = Model.deserialize(from: dict) else { return }
print(model.age)  // 10
print(model.name) // 小明
```





## SmartCodable 的继承

```
class BaseModel: SmartCodable {
    var name: String = ""
    required init() { }
}

@SmartSubclass
class Model: BaseModel {
    var age: Int = 0
}

let dict = [
    "name": "小明",
    "age": 10
] as [String : Any]

guard let model = Model.deserialize(from: dict) else { return }
print(model.age)  // 10
print(model.name) // 小明
```

> ⚠️ 需要使用5.0+版本。如果使用低版本，需要使用下面提供的方案。







## Codable 在4.0+如何处理继承的解析

Swift 编译器仅会对显式遵循`Codable`协议的**当前类型**自动合成编解码方法。

当父类遵循 `Codable` 时，其自身的属性会被自动处理。但子类新增属性不会被自动处理，因此我们需要**重写编解码方法，手动实现新增属性的编解码逻辑，并调用super实现**。

例如：（相比 `HandyJSON`显得繁琐一些😓）

```
class BaseModel: Codable {
    var name: String = ""
    required init() { }
}

class SubModel: BaseModel {
    var age: Int = 0
    
    private enum CodingKeys: CodingKey {
        case age
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.age = try container.decode(Int.self, forKey: .age)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(age, forKey: .age)
    }
    
    required init() { super.init() }
}
```


### 为什么子类必须手动实现？

我们可以通过`SIL（Swift Intermediate Language）`验证编译器的行为。
```
class BaseModel : Decodable & Encodable {

    @_hasStorage @_hasInitialValue var name: String { get set }
    required init()
    
    enum CodingKeys : CodingKey {
        case name
        
        func hash(into hasher: inout Hasher)
        init?(stringValue: String)
        init?(intValue: Int)
        var hashValue: Int { get }
        var intValue: Int? { get }
        var stringValue: String { get }
    }
    
    @objc deinit
    func encode(to encoder: Encoder) throws
    required init(from decoder: Decoder) throws
}
```

```
@_inheritsConvenienceInitializers class SubModel : BaseModel {
    @_hasStorage @_hasInitialValue var age: Int { get set }
    required init()
    required init(from decoder: Decoder) throws
    @objc deinit
}
```

可以看到：

- 对于父类，由于显式遵循了 `Codable`  协议，编译器自动合成了`init(from decoder:)`、`encode(to encoder:)`和`CodingKeys`

- 对于子类：

  - **不会自动合成** `encode(to:)`（不是 `required` 方法, 子类也没有显式的遵循`Codable`协议）


  - **不会自动合成** `CodingKeys`（没有显式的遵循`Codable`协议）


  - 会合成 `init(from:)`（因为是`required`初始化方法，合成的这个方法中**不会包含子类新增属性的解码逻辑**）


因此，若子类也有需要被编码/解码的属性, 就**必须在子类中重写** `init(from:)` 和 `encode(to:)`。



## SmartCodable 如何处理继承的解析

`SmartCodable` 是对原生 `Codable` 的增强，天然支持`Codable`继承的处理方案，也提供了其它方案选择，可以根据各自项目的情况选择最优方案。

- 基于继承的实现（类似原生Codable）
- 基于Protocol的实现
- 基于@SmartFlat的实现
- 基于Protocol + @SmartFlat的混合实现


### 方案一：基于继承的实现（同Codable）
与原生 Codable 实现类似，但使用 `SmartCodable` 增强解析器，具备类型容错能力。

**优点：**

- 原生 `Codable` 写法，符合直觉
- 支持类型不一致、字段缺失、nil等场景的容错

**缺点：**

- 子类仍需手动实现新增属性的编解码逻辑，代码量较多

```
class BaseModel: SmartCodable {
    var name: String = ""
    required init() { }
}

class SubModel: BaseModel {
    var age: Int = 0
    
    private enum CodingKeys: CodingKey {
        case age
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.age = try container.decode(Int.self, forKey: .age)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(age, forKey: .age)
    }
    
    required init() { super.init() }
}
```

### 方案二：基于Protocol的实现
通过协议定义公共属性，避免继承带来的复杂度。适用轻量级共享属性定义。
**优点：**

- 不需要手动实现子类编解码逻辑
- 子类间具有协议这个公共类型

**缺点：**

- 每个子类都需实现协议中的属性，存在一定重复
```
protocol BaseModel {
    var name: String { set get }
    var sex: Int { set get }
}

class SubModel: BaseModel, SmartCodable {
    required init() {}
    
    var name: String = ""
    var sex: Int = 0
    
    var age: Int = 0
}
```

### 方案三：基于@SmartFlat的实现
使用组合代替继承，将父类作为属性嵌入到子类中。`@SmartFlat`属性包装器会从当前JSON节点提取数据填充该属性。
**优点：**

- 不需要手动实现子类编解码逻辑
- 避免了`Protocol`方案中，各子类重复实现基协议的繁琐

**缺点：**

- 缺失子类间的公共类型
```
class BaseModel: SmartCodable {
    required init() {}
    
    var name: String = ""
    var sex: Int = 0
}

class SubModel: SmartCodable {
    required init() {}
    
    var age: Int = 0
    
    @SmartFlat
    var manBase: BaseModel = .init()
}

let dict = [
        "name": "小明",
        "sex": 1,
        "age": 10,
] as [String : Any]

guard let model = SubModel.deserialize(from: dict) else { return }
print(model.manBase.name) // 小明
print(model.manBase.sex)  // 1
print(model.age)  // 10
```

### 方案四：基于Protocol + @SmartFlat的实现
结合`Protocol` 和`@SmartFlat`两种方案的优点，规避各自的不足，比较灵活。
**优点：**

- 不需要手动实现子类编解码逻辑
- 避免了`Protocol`方案中，各子类重复实现基协议的繁琐
- 避免了`@SmartFlat`方案中，缺失了各子类的公共类型约束

**缺点：**

- 不是真正的继承😂

```
protocol ManBaseModelProtocol {
    var manBase: BaseModel { set get }
}

class BaseModel: SmartCodable {
    required init() {}
    
    var name: String = ""
    var sex: Int = 0
}

class SubModel: SmartCodable, ManBaseModelProtocol {
    required init() {}
    
    @SmartFlat
    var manBase: BaseModel = .init()
    
    var age: Int = 0
}
```