//
//  Test2ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/4/10.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SmartCodable
import BTPrint

class Test2ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()


//        test()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        test()
    }
    
    func test() {
        SmartSentinel.debugMode = .verbose
        
        
        let json = """
        {
            "color" : "0xffffff",
            "date": "1721745600"
        }        
        """
        
        let model = Model.deserialize(from: json)
        print(model?.color)
        print(model?.date)
        return
        
    }

    struct Model: SmartCodable {
        @IgnoredKey
        var color: UIColor?
        
        @SmartAny
        var date: Date?
        
        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.color <--- SmartHexColorTransformer(colorFormat: .rrggbb(.zeroX)),
                CodingKeys.date <--- SmartDateTransformer(strategy: .timestamp)
                
            ]
        }
    }


}




