//
//  Test2ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/4/10.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SmartCodable




class Test2ViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict: [String: Any] = [


            "url": ["http://www.baidu.com"],
            
            "float": 188.5,
//            
            "date": 1722152312,
        ]

        guard let model = Model.deserialize(from: dict) else { return }
        smartPrint(value: model)
        
        guard let transDict = model.toJSONString(prettyPrint: true) else { return }
        print(transDict)
    }
}


extension Test2ViewController {
    struct Model: SmartCodable {
        var url: [URL]?
//        var float: CGFloat = 100
//        var date: Date? = Date()
        
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.url <--- URLTransformer(),
//                CodingKeys.float <--- FloatTranformer(),
//                CodingKeys.date <--- SmartDateTransformer(strategy: .timestamp)
            ]
        }
    }
}
struct FloatTranformer: ValueTransformable {
    func transformFromJSON(_ value: Any) -> Object? {
        return 200.0
    }
    
    func transformToJSON(_ value: Object) -> JSON? {
        return nil
    }
    
    typealias Object = CGFloat
    
    typealias JSON = String
}
public struct URLTransformer: ValueTransformable {

    public typealias JSON = [String]
    public typealias Object = [URL]
    private let shouldEncodeURLString: Bool
    private let prefix: String?

    /**
     Initializes a URLTransformer with an option to encode the URL string before converting it to NSURL
     - parameter shouldEncodeUrlString: When true (the default value), the string is encoded before being passed
     - returns: an initialized transformer
    */
    public init(prefix: String? = nil, shouldEncodeURLString: Bool = true) {
        self.shouldEncodeURLString = shouldEncodeURLString
        self.prefix = prefix
    }
    
    
    public func transformFromJSON(_ value: Any) -> [URL]? {
        let url = URL(string: "1")!
        return [url]
    }

    public func transformToJSON(_ value: [URL]) -> [String]? {
        return ["1", "2", "3"]
    }
}
