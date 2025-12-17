

# 使用SmartCodable 平替 HandyJSON



## SmartCodable VS HandyJSON

| 序号 | 🎯 特性                        | 💬 特性说明 💬                                                 | SmartCodable | HandyJSON |
| ---- | ----------------------------- | ------------------------------------------------------------ | ------------ | --------- |
| 1    | **强大的兼容性**              | 完美兼容：**字段缺失** & **字段值为nul** & **字段类型错误**  | ✅            | ✅         |
| 2    | **类型自适应**                | 如JSON中是一个Int，但对应Model是String字段，会自动完成转化   | ✅            | ✅         |
| 3    | **解析Any**                   | 支持解析 **[Any], [String: Any]** 等类型                     | ✅            | ✅         |
| 4    | **解码回调**                  | 支持Model解码完成的回调，即：**didFinishingMapping**         | ✅            | ✅         |
| 5    | **属性初始化值填充**          | 当解析失败时，支持使用初始的Model属性的赋值。                | ✅            | ✅         |
| 6    | **字符串的Model化**           | 字符串是json字符串，支持进行Model化解析                      | ✅            | ✅         |
| 7    | **枚举的解析**                | 当枚举解析失败时，支持兼容。                                 | ✅            | ✅         |
| 8    | **属性的自定义解析** - 重命名 | 自定义解码key（对解码的Model属性重命名）                     | ✅            | ✅         |
| 9    | **属性的自定义解析** - 忽略   | 忽略某个Model属性的解码                                      | ✅            | ✅         |
| 10   | **支持designatedPath**        | 实现自定义解析路径                                           | ✅            | ✅         |
| 11   | **Model的继承**               | 使用`@SmartSubclass` 修饰SubModel                            | ✅            | ✅         |
| 12   | **自定义解析路径**            | 指定从json的层级开始解析                                     | ✅            | ✅         |
| 13   | **超复杂的数据解码**          | 解码过程中，多数据做进一步的整合/处理。如： 数据的扁平化处理 | ✅            | ⚠️         |
| 14   | **解码性能**                  | 在解码性能上，SmartCodable 平均强 30%                        | ✅            | ⚠️         |
| 15   | **异常解码日志**              | 当解码异常进行了兼容处理时，提供排查日志                     | ✅            | ❌         |
| 16   | **安全性方面**                | 底层实现的稳定性和安全性。                                   | ✅            | ❌         |

整体来讲： SmartCodable 和  HandyJSON 相比，在功能和使用上相近。


#### 安全性 & 稳定性

* **HandyJSON** 使用Swift的反射特性来实现数据的序列化和反序列化。**该机制是非法的，不安全的**， 更多的细节请访问 **[HandyJSON 的466号issue](https://github.com/alibaba/HandyJSON/issues/466)**.

* **Codable** 是Swift标准库的一部分，提供了一种声明式的方式来进行序列化和反序列化，它更为通用。



## 平替说明

| 内容项          | 内容项说明                                    | 使用场景 | 替换难度 | 评判理由                                               |
| --------------- | --------------------------------------------- | -------- | -------- | ------------------------------------------------------ |
| ①声明Model      | 声明Model                                     | ★★★★★    | ★☆☆☆☆    | 全局将 HandyJSON 替换为 SmartCodable即可。             |
| ②反序列化       | 数据的模型化（数据转Model）                   | ★★★★★    | ☆☆☆☆☆    | 完全一样的调用方式，无需处理。                         |
| ③序列化         | 模型的数据化（Model转数据）                   | ★☆☆☆☆    | ★☆☆☆☆    | 将 `toJSON()` 替换为 `toDictionary()` 或 `toArray()`。 |
| ④解码完成的回调 | 解析完成进一步处理数据                        | ★★☆☆☆    | ☆☆☆☆☆    | 完全一样的调用方式，无需处理。                         |
| ⑤自定义解析Key  | 忽略key的解析 & 自定义Key的映射关系           | ★★★☆☆    | ★★★☆☆    | 需要更改调用方式。                                     |
| ⑥解析Any        | 解析Any类型的数据。Any，[String: Any]， [Any] | ★☆☆☆☆    | ★☆☆☆☆    | 将Any替换为SmartAny                                    |
| ⑦处理继承关系   | 解析存在的继承关系的Model                     | ★☆☆☆☆    | ★☆☆☆☆    | 使用@SmartSubclass修饰子Model。                             |
| ⑧枚举的解析     | 解析枚举属性                                  | ★☆☆☆☆    | ★☆☆☆☆    | 多实现一个 defaultCase                                 |



## 平替指导

### 1. 声明Model

除了遵守的协议不同外，其他一样。你只需要做一件事，将 **HandyJSON** 替换为 **SmartCodable**。

#### HandyJSON

```
import HandyJSON
```

* class类型的Model

```
class HandyModel: HandyJSON {
    var name: String = ""
    required init() { }
}
```

* struct类型的Model

```
struct HandyModel: HandyJSON {
    var name: String = ""
}
```



#### SmartCodable

```
import SmartCodable
```

* class类型的Model

```
class SmartModel: SmartCodable {
    var name: String = ""
    required init() { }
}
```

* struct类型的Model

```
struct SmartModel: SmartCodable {
    var name: String = ""
}
```



### 2. 反序列化

在反序列化中，可以 **完全无障碍的平替**，不需要代码改动。

> 注意：使用HandyJSON解码数组时候，需要使用 as? [HandyModel] 进行可选解包。SmartCodable中是不需要的，当然不删除也不会报错。
>
> 你可以全局搜索 **) as? [** ，查找删除。

#### HandyJSON

解析字典数据和数组数据

```
guard let handyModel = HandyModel.deserialize(from: dict) else { return }

guard let handyModels = [HandyModel].deserialize(from: [dict]) as? [HandyModel] else { return }
```

#### SmartCodable

解析字典数据和数组数据

```
guard let smartModel = SmartModel.deserialize(from: dict) else { return }

guard let smartModels = [SmartModel].deserialize(from: [dict]) else { return }
```



### 3. 序列化

在序列化中，需要少量的代码改动。需要将 `toJSON()` 替换为 `toDictionary()` 或 `toArray()`。

序列化的使用场景较少，应该影响不大。

#### HandyJSON

* 将模型序列化字典或json字符串

```
let toDict = handyModel.toJSON()
let toJsonStr = handyModel.toJSONString()
```

* 将模型序列化数组或json字符串

```
let toArr = handyModels.toJSON()
let toArrStr = handyModels.toJSONString()
```

#### SmartCodable

* 将模型序列化字典或json字符串

```
let toDict1 = smartModel.toDictionary()
let toJsonStr1 = smartModel.toJSONString()
```

* 将模型序列化数组或json字符串

```
let toArr1 = smartModels.toArray()
let toArrStr1 = smartModels.toJSONString()
```







### 4. 解码完成的回调

使用 `didFinishMapping` 处理解码完成时的回调。 两者完全一样，不需要任何替换工作量。

#### HandyJSON

```
struct HandyModel: HandyJSON {
    var name: String = ""
    func didFinishMapping() {   
    }
}
```

#### SmartCodable

```
struct SmartModel: SmartCodable {
    var name: String = ""
    func didFinishMapping() {       
    }
}
```





### 5. 自定义解析key

这个情况下，需要较大的工作量，处理自定义解析策略。

分为两种情况：

* 忽略某些key的映射
* 自定义key的映射

#### HandyJSON

在 `mutating func mapping(mapper: HelpingMapper) `方法中

通过 `mapper >>>` 处理解析的忽略；

通过 `mapper <<<` 自定义映射关系。

```
struct HandyModel: HandyJSON {
    var name: String = ""
    var age: Int?
    var ignoreKey: String = "忽略的key"
    
    mutating func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.name <-- ["nick_name", "realName"]
        mapper <<<
            self.age <-- "self_age"
        mapper >>>
            self.ignoreKey
    }
}
```

#### SmartCodable

通过重写 `CodingKeys` 删除不需要解析的`case`，达到忽略解析的目的。

通过`func mapping()` 自定义映射关系。

```
struct SmartModel: SmartCodable {
    var name: String = ""
    var age: Int?
    var ignoreKey: String = "忽略的key"
    
    enum CodingKeys: CodingKey {
        case name
        case age
//            case ignoreKey
    }

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [
            CodingKeys.name <--- ["nick_name", "realName"],
            CodingKeys.age <--- "self_age"
        ]
    }
}
```







### 6. 解析Any

在Any的解析中，HandyJSON可以无障碍的解析Any。但是SmartCodable需要借助 **SmartAny** 类型解析。

#### HandyJSON

```
struct HandyModel: HandyJSON {
    var name: Any?
    var dict: [String: Any] = [:]
}

guard let handyModel = HandyModel.deserialize(from: dict) else { return }
print(handyModel.name)
print(handyModel.dict)
```



#### SmartCodable

需要借助 **SmartAny** 类型解析，并且在使用解析数据的时候，需要调用 `peel` 解包。

```
struct SmartModel: SmartCodable {
    @SmartAny
    var name: Any?
    
    @SmartAny
    var dict: [String: Any] = [:]
}

guard let smartModel = SmartModel.deserialize(from: dict) else { return }
print(smartModel.name)
print(smartModel.dict)
```



## 7. 处理继承关系

HandyJSON可以无障碍的支持解析继承关系。但是SmartCodable需要手动处理继承关系的解析。

#### HandyJSON

```
class HandyBaseModel: HandyJSON {
    var name: String?
    required init() { }
}

class HandyModel: HandyBaseModel {
    var age: Int?
}
```



#### SmartCodable

```
class BaseModel: SmartCoable {
    var name: String?
    required init() { }
}

@SmartSubclass
class HandyModel: BaseModel {
    var age: Int?
}
```



### 8. 枚举的解析

需要做一定的兼容。

#### HandyJSON

```
enum HandySex: String, HandyJSONEnum {
    case man
    case women
}

struct HandyModel: HandyJSON {
    var sex: HandySex = .man
}
```



#### SmartCodable

```
enum SmartSex: String, SmartCaseDefaultable {
    case man
    case women
}

struct SmartModel: SmartCodable {
    var sex: SmartSex = .man
}
```

