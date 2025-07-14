//
//  TestViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/1.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import SmartCodable
import HandyJSON
import CleanJSON
import BTPrint


class TestViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let jsonStringArray = [
                """
                {
                    "code" : 200,
                    "message" : "success",
                    "data" : {
                        "status" : null,
                        "distance" : 12345
                    }
                }
                """,
                """
                {
                    "code" : 200,
                    "message" : "success",
                    "data" : {
                        "status" : "A",
                        "distance" : 12345
                    }
                }
                """,
                """
                {
                    "message" : "success",
                    "data" : {
                        "status" : null,
                        "distance" : 12345      
                    }
                }
                """,
                """
                {
                    "code" : 200,
                    "message" : "success",
                    "data" : {
                        "distance" : 12345
                    }
                }
                """
        ]
        let results = jsonStringArray.map { jsonString in
            let data = jsonString.data(using: .utf8)
            let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
            return ApiData<Trip>.deserialize(from: json) != nil
        }
        print(results)

    }
    
    
    struct ApiData<T>:@unchecked Sendable, SmartCodable, Error {
        var code: Int?
        var message: String?
        @SmartAny
        var data: T?
        var time: Double?
        var token: String?
        @SmartAny
        var metaData: Any?
    }

    struct Trip: SmartCodable {
        var status: Status?
        var distance: Int = 0
        
        enum Status: String, SmartCaseDefaultable {
            case a = "A"
            case b = "B"
        }
    }

}

