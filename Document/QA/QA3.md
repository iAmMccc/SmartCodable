# QA3 支持属性初始化值填充



在Codable中，如果属性遇到以下情况的值： 

* 字段缺失
* 值为null
* 值类型错误

就会解析异常，抛出DecodingError。

```swift
do {
    let decoder = SmartJSONDecoder()
    let decodeValue = try decoder.decode(type, from: data)
    return decodeValue
} catch {
    // SmartCodable 内部会捕获异常并进行容错处理
    return nil
}
```



SmartCodable最初的诉求就是为了解决该问题。进而产生了三个演化的版本。

* 解析失败，使用类型默认值进行填充
* 尝试转换数据类型，如果还是失败，使用默认值填充。
* 解析失败，使用属性初始化的值填充。

当解析失败时：会按照 **尝试转化数据类型 > 属性初始化值 > 属性类型默认值** 进行兼容。



## 使用默认值

```
protocol Defaultable {
    static var defaultValue: Self { get }
}

extension String: Defaultable {
    static var defaultValue: String { "" }
}

extension Bool: Defaultable {
    static var defaultValue: Bool { false }
}

......
```

SmartCodable声明了该协议，为支持Codable的类型实现了该协议。

当解析失败，需要兼容的时候，通过类型T，获取对应的填充值

```
if let value = T.self as? Defaultable.Type {
    return value.defaultValue as! T
}
```



## 转换数据类型

我们会遇到一些有意思的情况： 

声明的属性类型是Bool，但是数据值是： String类型的“true”，“false”等，Int类型的0，1等。在逻辑上它们也是有意义的。为了实现这个转换需求，声明了该协议：

```
fileprivate protocol ValueTransformable {
    static func transformValue(from value: Any) -> Self?
}
```

并为我们需要转换的类型实现了该协议： 

```
extension Bool: ValueTransformable {
    static func transformValue(from value: Any) -> Bool? {
        switch value {
        case let temp as Int:
            if temp == 1 { return true}
            else if temp == 0 { return false }
        case let temp as String:
            if ["1","YES","Yes","yes","TRUE","True","true"].contains(temp) { return true }
            if ["0","NO","No","no","FALSE","False","false"].contains(temp) { return false }
        default:
            break
        }
        return nil
    }
}
```

当解析失败的时候，尝试对值进行类型转换的处理：

```
struct Transformer {
    static func typeTransform(from jsonValue: Any?) -> T? {
        guard let value = jsonValue else { return nil }
        return (T.self as? ValueTransformable.Type)?.transformValue(from: value) as? T
    }
}
```



## 使用属性初始化的值填充

有一个使用者提出，是否可以像HandyJSON一样，当解析失败直接使用初始化值填充。 例如：

```
struct NameModel: SmartCodable {
    var name: String = "我是初始值"
}

let dict: [String: String] = [ : ]
if let model = NameModel.deserialize(dict: dict) {
    print(model.name)
    // 我是初始值
}
```

为了实现该功能，SmartCodable 重新实现了完整的 JSON 解码器（`SmartJSONDecoder`），而非仅重写 `JSONKeyedDecodingContainer` 的协议方法。

核心实现在 `DecodingCache` 中，通过快照机制记录当前正在解析的 Model 的初始值：

```swift
// DecodingCache.swift 简化示意
func cacheSnapshot<T>(for type: T.Type, codingPath: [CodingKey]) {
    guard let smartType = type as? SmartDecodable.Type else { return }
    let snapshot = DecodingSnapshot(objectType: smartType, codingPath: codingPath)
    snapshots.append(snapshot)
}

// 懒加载：首次需要默认值时才通过 Mirror 反射获取
private func populateInitialValues(snapshot: DecodingSnapshot) {
    guard let type = snapshot.objectType else { return }
    let mirror = Mirror(reflecting: type.init())
    // 提取所有属性的初始值存入 snapshot.initialValues
}
```

当某个属性解码失败时，从快照中找到该属性的初始值进行填充。这种懒加载设计避免了每次解码都进行反射，只有在真正需要回退默认值时才会触发。