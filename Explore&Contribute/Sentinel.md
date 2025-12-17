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

