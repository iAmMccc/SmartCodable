## Usages

### 1. Decoding dictionary（解码字典）

```
import SmartCodable

struct Model: SmartCodable {
    var name: String = ""
}

let dict: [String: String] = ["name": "xiaoming"]
guard let model = Model.deserialize(from: dict) else { return }
```



### 2. Decode array（解码数组）

```
import SmartCodable

struct Model: SmartCodable {
    var name: String = ""
}

let dict: [String: String] = ["name": "xiaoming"]
let arr = [dict, dict]
guard let models = [Model].deserialize(from: arr) else { return }
```



###  3. Serialization（序列化）

```
// to model
guard let xiaoMing = JsonToModel.deserialize(from: dict) else { return }

// to dict
let studentDict = xiaoMing.toDictionary() ?? [:]

// to json
let json1 = xiaoMing.toJSONString(prettyPrint: false) ?? ""
```



### 4. designatedPath (指定的路径)

SmartCoable supports deserialization from designated path of JSON. 

SmartCoable支持从指定路径的JSON进行反序列化。

```
let jsonString = """
    {
        "people": [
            {
                "name": "John Doe",
                "age": 30
            },
            {
                "name": "Jane Smith",
                "age": 25
            }
        ]
    }
"""

struct PathModel: SmartCodable {
    var name: String?
    var age: Int?
}

if let models = [PathModel].deserialize(from: jsonString, designatedPath: "people") {
  print(models)
}
```



### 5. Composition Object（组成对象）

Notice that all the properties of a class/struct need to deserialized should be type conformed to `SmartCodable`.

注意，类/结构体中所有需要反序列化的属性都应该符合 `SmartCodable`。

```
struct Model: SmartCodable {
    var name: String = "Mccc"
    var sub: SubModel?
}
struct SubModel: SmartCodable {
    var name: String = ""
}
```



## Custom decoding types（自定义的解析类型）

### 1. Decoding Any（解码Any）

Codable does not decode the Any type, meaning that the attribute type of the model cannot be **Any**， **[Any]** and **[String: Any]**.

**SmartAny** is a solution to Any provided by **SmartCodable**.

Codable是无法解码Any类型的，意味着模型的属性类型不可以是 **Any**，**[Any]** 和 **[String: Any]** 类型。**SmartCodable** 提供了 **SmartAny** 来解决改它。

```
struct AnyModel: SmartCodable {
    @SmartAny
    var name: Any?
    
    @SmartAny
    var dict: [String: Any] = [:]
    
    @SmartAny
    var arr: [Any] = []
}
```

```
let dict = [
    "name": "xiao ming",
    "age": 20,
    "dict": inDict,
    "arr": arr
] as [String : Any]

guard let model = AnyModel.deserialize(from: dict) else { return }
```



⚠️： SmartAny 只允许修饰**Any**，**[Any]** 和 **[String: Any]** 类型。

```
// ❌ 错误的示范
struct Model<T: SmartCodable>: SmartCodable {
    @SmartAny
    var data: T?
}

struct SubModel: SmartCodable {
    var name: String?
}
```

⚠️： SmartAny 是通过Swift中属性包装器实现的，如果你用反射获取属性名，或被添加"_"，这是属性包装器的特性。请注意。
```
let e = Mirror(reflecting: self).children
for item in e {
   print(item.label)
}
```


### 2.Modeling of json strings（json字符串的模型化）

```
let dict: [String: Any] = [
    "hobby": "{\"name\":\"sleep\"}",
]
guard let model = Model.deserialize(from: dict) else { return }
print(model)

struct Model: SmartCodable {
    var hobby: Hobby?
}

struct Hobby: SmartCodable {
    var name: String = ""
}
```



### 3. Decoding UIColor（解析UIColor）

Use SmartColor instead of UIColor.

```
let dict = [
    "color": "7DA5E3"
]

struct Model: SmartCodable {
    var color: SmartColor?
}

guard let model = Model.deserialize(from: dict) else { return }
print(model.color?.peel)
```

> **UIColor** 是 `non-final class`。非最终类不能简单地实现`Codable`的`init(from:)`。



### 4. Decoding enum（解码枚举）

Make the enumeration follow **SmartCaseDefaultable**.

让枚举遵循 **SmartCaseDefaultable**。

```
struct Model: SmartCodable {
    var enum: MyEnum?
}

enum myEnum: String, SmartCaseDefaultable {
    case a
    case b
    case c = "hello"
}
```

#### Decoding of associative value enum（支持关联值枚举的解码）

Make the enumeration follow **SmartAssociatedEnumerable**。Override the **mappingForValue** method and take over the decoding process yourself.

让枚举遵循 **SmartAssociatedEnumerable**，重写mappingForValue方法，你自己接管解码过程。

```
enum Sex: SmartAssociatedEnumerable {    
    case man
    case women
    case other(String)
}
struct Model: SmartCodable {
    var sex: Sex = .man
    static func mappingForValue() -> [SmartValueTransformer]? {
        [
            CodingKeys.sex <--- RelationEnumTranformer()
        ]
    }
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



## Compatibility（兼容性）

If attribute resolution fails, SmartCodable performs compatibility processing for thrown exceptions. Ensure that the entire parsing is not interrupted. Even better, you don't have to do anything about it.

某个属性解析失败时候，SmartCodable会接管抛出的异常，进行兼容性处理。确保整个解析不会被中断。更好的是不需要你为此做任何事情。

```
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



### Type conversion compatibility（类型转化的兼容）

When the data is parsed, the type cannot be matched. Raises a.typeMismatch error. SmartCodable will attempt to convert data of type String to the desired type Int.

当对该数据进行解析时，由于不能匹配类型。会抛出`.typeMismatch` error。SmartCodable 会尝试将 String类型的数据 转换为 所需的 Int 类型数据。

### Default Fill compatible（使用填充值的兼容） 

When the type conversion fails, the initialization value of the currently parsed property is retrieved for padding.

当类型转换失时，会获取当前解析的属性的初始化值进行填充。



## User-defined Key when decoding（自定义Key）

### 1. Ignore key parsing（忽略key的解析）

```
struct Model: SmartCodable {
    var name: String = ""
    var ignore: String = ""
    var age: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case name
        case age
    }
}
```

If you don't want **ignore** to participate in parsing, delete it in **CodingKeys** and you'll be left with parsing. But with SmartCodable, you can use @IgnoredKey.

如果你不希望 **ignore** 参与解析，就在 **CodingKeys** 中删除它，留下的就是参与解析的。但有了 `SmartCodable` ，你就可以使用 `@IgnoredKey` .

```
struct Home: SmartCodable {
    var name: String = ""
    @IgnoredKey
    var age: [Any] = ["1"]
    @IgnoredKey
    var area: String = "area"
}
```



### 2. Rename Key when decoding（key的重命名）

```
public enum SmartKeyDecodingStrategy : Sendable {
    case useDefaultKeys
    
    // 蛇形命名转驼峰命名
    case fromSnakeCase
    
    // 首字母大写转小写
    case firstLetterLower
    
    // 首字母小写转大写
    case firstLetterUpper
}
```

```
let option1: SmartDecodingOption = .key(.fromSnakeCase)
guard let model1 = TwoModel.deserialize(from: dict1, options: [option1]) else { return }
```



If you only need to change the mapping rules of a Model Key, you can override `mappingForKey` and complete the mapping relationship as required.

如果你只需要修改某个Model的Key的映射规则，可以重写 `mappingForKey` , 按照要求完成映射关系。

```
struct Model: SmartCodable {
    var name: String = ""
    var age: Int = 0

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [
            CodingKeys.age <--- "person_age"
            CodingKeys.name <--- ["nickName", "realName"],
        ]
    }
}
```

### 3. designatedPath （指定解析路径）

Override 'mappingForKey` to specify the parsing path

重写`mappingForKey` 可以实现跨层解析。

```
let dict = [
    "age": 10,
    "sub": [
        "name": "Mccc"
    ]
]
```

```
struct Model: SmartCodable {
    var age: Int = 0
    var name: String = ""
    static func mappingForKey() -> [SmartKeyTransformer]? {
        [ CodingKeys.name <--- "sub.name" ]
    }
}
```

### 

## User-defined Value when decoding(自定义Value)

SmartDecodingOption provides three decoding options:

SmartDecodingOption提供了三种解码选项，分别为：

```
public enum SmartDecodingOption {
    
    /// 用于解码 “Date” 值的策略
    case dateStrategy(JSONDecoder.DateDecodingStrategy)
    
    /// 用于解码 “Data” 值的策略
    case dataStrategy(JSONDecoder.DataDecodingStrategy)
    
    /// 用于不符合json的浮点值(IEEE 754无穷大和NaN)的策略
    case floatStrategy(JSONDecoder.NonConformingFloatDecodingStrategy)
}
```

* Date

```
let dateFormatter = DateFormatter()
 dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
let option: JSONDecoder.SmartDecodingOption = .dateStrategy(.formatted(dateFormatter))
guard let model = FeedOne.deserialize(from: json, options: [option]) else { return }
```

* Data

```
let option: JSONDecoder.SmartDecodingOption = .dataStrategy(.base64)
guard let model = FeedOne.deserialize(from: json, options: [option]) else { return }
gurad let data = model.address, let url = String(data: data, encoding: .utf8) { else }
```

* Float

```
let option: JSONDecoder.SmartDecodingOption = .floatStrategy(.convertFromString(positiveInfinity: "infinity", negativeInfinity: "-infinity", nan: "NaN"))
guard let model1 = FeedOne.deserialize(from: json, options: [option]) else {  return }
```



If you want to control the scope of influence, you can override `mappingForValue` to give each attribute a different parsing policy.

如果你想控制影响范围，可以重写 `mappingForValue`，给每个属性设置不同的解析策略。

```
struct SmartModel: SmartCodable {
    var date1: Date?
    var date2: Date?
    var url: URL?
    var data: Data?
            
    static func mappingForValue() -> [SmartValueTransformer]? {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        return [
            CodingKeys.url <--- SmartURLTransformer(prefix: "https://"),
            CodingKeys.date2 <--- SmartDateTransformer(),
            CodingKeys.date1 <--- SmartDateFormatTransformer(format),
            CodingKeys.data <--- SmartDataTransformer()
        ]
    }
}
```



### Customize Transformer (自定义)

If you need additional parsing rules, **Transformer** will implement them yourself. Follow **ValueTransformable** to implement the requirements of the protocol.

如果你需要额外的解析规则，**Transformer** 交给你自己实现。请遵循 **ValueTransformable**，实现协议的相关要求。 

```
public protocol ValueTransformable {
    associatedtype Object
    associatedtype JSON
    
    /// transform from ’json‘ to ’object‘
    func transformFromJSON(_ value: Any?) -> Object?
    
    /// transform to ‘json’ from ‘object’
    func transformToJSON(_ value: Object?) -> JSON?
}
```



## Decoded finish

### Parse the completed callback （解析完成的回调）

When decoding is complete, **didFinishMapping** is called. You can rewrite it.

当解码完成时，调用 **didFinishMapping**。你可以重写它。

```
class Model: SmartDecodable {

    var name: String = ""
    var age: Int = 0
    var desc: String = ""
    required init() { }
    

    func didFinishMapping() {    
        if name.isEmpty {
            name = "-"
        }
    }
}
```



### extend（继承）

Inheritance does not have a particularly good implementation in Codable, but SmartCodable provides a combination (@SmartFlat) that indirectly implements inheritance requirements.

继承在Codable中没有特别好的实现方案， 这里提供两种方案：

1. SmartCodable提供了组合方式（@SmartFlat）用来间接实现继承的需求。

```
let jsonString = """
{
    "a": "aa",
    "b": 100,
    "longitude": 3,
    "latitude": 4
}
"""
if let model = SubModel.deserialize(from: jsonString) {
    smartPrint(value: model.c)
}

struct SuperModel: SmartCodable {
    var longitude: Double?
    var latitude: Double?
}
struct SubModel: SmartCodable {
    var a: String?
    var b: Int?
    
    @SmartFlat
    var c: SuperModel?
}
```

2. 重写`init(from decoder: Decoder) `  方法，接管解析。

   ```
   class BaseModel: SmartCodable {
       var name: String = ""
       var age: Int = 0
       
       enum CodingKeys: CodingKey {
           case name
           case age
       }   
       required init() { }
   }
   
   class SubModel: BaseModel {
       var nickName: String = ""    
       enum CodingKeys: CodingKey {
           case nickName
       }
       required init(from decoder: Decoder) throws {
           try super.init(from: decoder)   
           let container = try decoder.container(keyedBy: CodingKeys.self)
           self.nickName = try container.decode(String.self, forKey: .nickName)
       }
       
       required init() {
           super.init()
       }
   }
   ```

   

### Update Existing Model（更新现有模型）

```
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

It can accommodate any data structure, including nested array structures.

它可以适应任何数据结构，包括嵌套的数组结构。
