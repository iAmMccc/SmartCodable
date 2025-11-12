//
//  Test2ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/4/10.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SmartCodableKit




class Test2ViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let dict: [String: Any] = [
            "my_name": "Tom",
            "student": [
                "my_age": "18"
            ]
        ]
        let person = Person.deserialize(from: dict,options: [.key(.fromSnakeCase)])
        print("1111")
    }
    
    class Person: SmartCodable {
        var myName: String?
        var student: Student?
        required init() {}
    }
    class Student: SmartCodable {
        var myAge: String?
        required init() {}
        
        static func mappingForKey() -> [SmartKeyTransformer]? {
            return [
                CodingKeys.myAge <--- "my_name"
            ]
        }
    }
}


