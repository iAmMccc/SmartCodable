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
            "code" : 200,
            "message" : "success",
            "data" : {
                "status": null,
                "distance" : 12345
            }
        }        
        """
        
        let model = ApiData.deserialize(from: json)
        print(model as Any)
        return
        
    }

    struct ApiData: SmartCodable {
        @SmartAny var data: Trip?
        @SmartAny var metaData: Any? = "默认值"
    }

    struct Trip: SmartCodable {
        var status: Status?
        
        enum Status: String, SmartCaseDefaultable {
            case a = "A"
            case b = "B"
        }
    }

}



//
//extension String: SmartCodable {
//
//}

