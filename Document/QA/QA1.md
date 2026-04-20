# QA1 在 mapping 方法中支持解析忽略



## 如何使用CodingKeys 忽略

在Swift中，使用`Codable`协议进行数据的序列化和反序列化时，我们有时候会遇到一种情况，就是JSON数据中包含了一些我们模型里没有定义的属性，或者我们的模型中有一些属性我们不想从JSON中解析。这时，我们可以通过自定义`CodingKeys`枚举来选择性地忽略这些属性。

`CodingKeys`是一个遵循`CodingKey`协议的枚举，用于为模型的属性指定与JSON中键的对应关系。如果你不想从JSON中解析某些属性，或者不想将某些属性编码到JSON中，你可以简单地在`CodingKeys`枚举中不声明这些属性。这样，`Codable`就会自动忽略这些不在`CodingKeys`中的属性。



```
struct User: Codable {
    var name: String
    // 假设我们不想从JSON中解析email属性
    var email: String?

    private enum CodingKeys: String, CodingKey {
        case name
        // 注意，我们没有包含email
    }
}

// 示例用于解析
let json = """
{
    "name": "John Doe",
    "email": "john@example.com"
}
""".data(using: .utf8)!

do {
    let user = try JSONDecoder().decode(User.self, from: json)
    print("解析成功: \(user)")
} catch {
    print("解析失败: \(error)")
}
```



## 如何理解CodingKeys忽略的原理

理解Swift中`JSONDecoder`如何处理`CodingKeys`以忽略某些属性，需要深入到`Codable`协议的工作机制中。我尝试以更简单的方式解释这个过程：

1. **基本概念**: 当你使用`Codable`进行编解码时，Swift自动使用你的模型的属性名作为JSON中的键名。如果属性名和JSON中的键名不匹配，或者你想忽略某些属性，你就需要自定义`CodingKeys`枚举。
2. **使用`CodingKeys`**: `CodingKeys`枚举让你可以指定哪些属性应该被编解码，以及它们对应JSON中的哪些键。只有在`CodingKeys`中列出的属性会被考虑进编解码过程。
3. **忽略属性**: 如果你不在`CodingKeys`枚举中列出某个属性，`Codable`就会自动忽略这个属性，不会尝试从JSON中读取它，也不会在编码时将其写入JSON。





## 回顾一下decode的流程

### 1. JSONDecoder 的 decode

```
open func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T {
    
    
    let topLevel: Any
    do {
       topLevel = try JSONSerialization.jsonObject(with: data)
    } catch {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid JSON.", underlyingError: error))
    }

    let decoder = _JSONDecoder(referencing: topLevel, options: self.options)
    guard let value = try decoder.unbox(topLevel, as: T.self) else {
        throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
    }

    return value
}
```

关键方法在这两个API上：

* 生成了一个decoder `let decoder = _JSONDecoder(referencing: topLevel, options: self.options) ` 

* 进行unbox   `let value = try decoder.unbox(topLevel, as: T.self)`



### 2. _JSONDecoder 的 unbox 方法

```
fileprivate func unbox<T : Decodable>(_ value: Any, as type: T.Type) throws -> T? {
    
    let decoded: T
    if T.self == Date.self || T.self == NSDate.self {
        guard let date = try self.unbox(value, as: Date.self) else { return nil }
        decoded = date as! T
    } else if T.self == Data.self || T.self == NSData.self {
        guard let data = try self.unbox(value, as: Data.self) else { return nil }
        decoded = data as! T
    } else if T.self == URL.self || T.self == NSURL.self {
        // 略
    } else if T.self == Decimal.self || T.self == NSDecimalNumber.self {
        // 略
    } else {
        
        self.storage.push(container: value)
        decoded = try T(from: self)
        
        self.storage.popContainer()
    }
    return decoded
}
```

我们重点关注 **else** 的部分:

```
self.storage.push(container: value)
decoded = try T(from: self)        
self.storage.popContainer()
```

为什么对 **T** 进行 **Decodable**的 **init(from:)** 操作，可以对 **T** 内部的全部属性进行decode呢?



这涉及到另外一个知识点： **编译的隐式处理**。

> Swift编译器在处理`Codable`时，其实并不会直接关注你的`CodingKeys`枚举里有哪些具体的键。编译器的“隐式处理”主要是基于你提供的`CodingKeys`枚举来确定哪些属性需要参与序列化和反序列化过程。下面是编译器在处理`Codable`相关代码时进行的一些隐式操作：
>
> ### 自动生成`CodingKeys`
>
> 如果你没有为遵循`Codable`协议的类型显式定义`CodingKeys`枚举，Swift编译器会自动生成一个`CodingKeys`枚举。这个自动生成的枚举包含类型所有属性的键，每个键的名称都与对应的属性名称相同。
>
> ### 基于`CodingKeys`生成编解码逻辑
>
> 当你提供了自定义的`CodingKeys`枚举时，编译器会使用这个枚举来确定哪些属性应该被包含在编解码过程中。只有在`CodingKeys`枚举中出现的属性才会被考虑。
>
> - **编码**: 在编码（序列化）过程中，编译器会为每个在`CodingKeys`中定义的键生成代码，将对应属性的值编码到序列化格式中（例如，JSON）。
> - **解码**: 在解码（反序列化）过程中，编译器同样只会查找和尝试解码`CodingKeys`枚举中指定的键对应的值。如果JSON中包含了额外的键，这些键会被忽略，除非解码器被特别指定要处理未知键。
>
> ### 错误处理
>
> 如果在解码过程中遇到了类型不匹配、缺少键或其他问题，Swift的`Codable`实现会抛出错误，例如`DecodingError.keyNotFound`、`DecodingError.typeMismatch`等。这部分逻辑也是编译器自动为你的`Codable`实现添加的。
>
> ### 优化和简化
>
> Swift编译器还会进行一些优化，以减少手写`Codable`实现时可能的样板代码。例如，当类型中的所有属性都是`Codable`时，你不需要为这个类型编写任何编解码逻辑；编译器会自动为你生成这些代码。
>
> 这种“隐式处理”大大简化了在Swift中使用`Codable`的复杂性，让开发者能够更加专注于模型的设计，而不是序列化和反序列化的细节。如果你需要更细致地控制编解码过程，比如处理复杂的数据结构或条件性编解码，你仍然可以通过自定义`init(from:)`和`encode(to:)`方法来实现。



再提出一个问题： 为什么要使用CodingKeys才可以修改属性名？



### CodingingKeys的隐式处理

跟OC中的Clang一样，Swift代码在编译过程中也会将Swift代码转换成中间码，即：SIL.

```
struct User : Decodable & Encodable {

 @_hasStorage var name: String { get set }

 @_hasStorage @_hasInitialValue var email: String? { get set }

 private enum CodingKeys : String, CodingKey {

  case name

  init?(rawValue: String)

  init?(stringValue: String)

  init?(intValue: Int)

  typealias RawValue = String

  var intValue: Int? { get }

  var rawValue: String { get }

  var stringValue: String { get }

 }

 func encode(to encoder: Encoder) throws

 init(from decoder: Decoder) throws

 init(name: String, email: String? = nil)

}
```

SIL中间码会对遵守Codable的代码默认生成CodingKeys，并且会根据CodingKeys处理编解码的映射关系。因此需要重写CodingKeys才可以自定义解码需求。



同样也可以解释为什么自定义的CodingKeys需要声明在结构体内部才可以生效，也就意味着不存在全局的CodingKeys，每一个CodingKeys只对当前的模型生效。



###  User.init(from:)的隐式处理

对 **User.init(from:)** 进行SIL的结果：

```
// User.init(from:)

sil hidden @$s18TestViewController4UserV4fromACs7Decoder_p_tKcfC : $@convention(method) (@in Decoder, @thin User.Type) -> (@owned User, @error Error) {

// %0 "decoder"                  // users: %51, %36, %10, %3
// %1 "$metatype"

bb0(%0 : $*Decoder, %1 : $@thin User.Type):

 %2 = alloc_stack [lexical] $User, var, name "self", implicit // users: %25, %5, %37, %52, %54, %38

 debug_value %0 : $*Decoder, let, name "decoder", argno 1, implicit, expr op_deref // id: %3

 debug_value undef : $Error, var, name "$error", argno 2 // id: %4

 %5 = struct_element_addr %2 : $*User, #User.email // user: %8

 %6 = enum $Optional<String>, #Optional.none!enumelt // users: %45, %41, %34, %32, %8, %7

 retain_value %6 : $Optional<String>       // id: %7

 store %6 to %5 : $*Optional<String>       // id: %8

 %9 = alloc_stack [lexical] $KeyedDecodingContainer<User.CodingKeys>, let, name "container", implicit // users: %31, %30, %22, %48, %47, %14, %42

 %10 = open_existential_addr immutable_access %0 : $*Decoder to $*@opened("E27EBBFE-E68A-11EE-A740-1EFE426E258A") Decoder // users: %14, %14, %13

 %11 = metatype $@thin User.CodingKeys.Type

 %12 = metatype $@thick User.CodingKeys.Type   // user: %14

 %13 = witness_method $@opened("E27EBBFE-E68A-11EE-A740-1EFE426E258A") Decoder, #Decoder.container : <Self where Self : Decoder><Key where Key : CodingKey> (Self) -> (Key.Type) throws -> KeyedDecodingContainer<Key>, %10 : $*@opened("E27EBBFE-E68A-11EE-A740-1EFE426E258A") Decoder : $@convention(witness_method: Decoder) <τ_0_0 where τ_0_0 : Decoder><τ_1_0 where τ_1_0 : CodingKey> (@thick τ_1_0.Type, @in_guaranteed τ_0_0) -> (@out KeyedDecodingContainer<τ_1_0>, @error Error) // type-defs: %10; user: %14

 try_apply %13<@opened("E27EBBFE-E68A-11EE-A740-1EFE426E258A") Decoder, User.CodingKeys>(%9, %12, %10) : $@convention(witness_method: Decoder) <τ_0_0 where τ_0_0 : Decoder><τ_1_0 where τ_1_0 : CodingKey> (@thick τ_1_0.Type, @in_guaranteed τ_0_0) -> (@out KeyedDecodingContainer<τ_1_0>, @error Error), normal bb1, error bb3 // type-defs: %10; id: %14
```

会把模型的每一个属性都提取出来，然后用KeyedDecodingContainer做decode操作。



### 总结一下

Codable 是通过 隐式实现的 CodingKeys 实现的解析映射，如果想要改变这个必须重写CodingKeys。 目前作者没有技术方法可以控制这种重新（在Model外）。



## 使用 @SmartIgnored 忽略

```swift
struct Home: SmartCodable {
    var name: String = ""

    @SmartIgnored
    var area: String = ""
}
```

SmartCodable 提供了属性包装器 `@SmartIgnored` 来忽略 JSON 中对应字段的解析。其实现原理是**伪忽略**——属性仍然会参与解码流程，但在解码时主动抛出异常，触发失败兜底逻辑，使用属性的初始化值替代 JSON 中的值。

> **注意**：在早期版本中，该属性包装器名为 `@IgnoredKey`，已在后续版本中重命名为 `@SmartIgnored`。

**性能建议**：对于大数据量解析场景，如果有大量属性不需要参与解码，推荐使用 `CodingKeys` 排除（编译期处理），而非 `@SmartIgnored`（运行时处理），性能更优。