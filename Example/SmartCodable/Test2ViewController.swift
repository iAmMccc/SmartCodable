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
        

    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let dict: [String: Any] = [
            "my_name": "Tom",
            "student": [
                "my_age": "18",
                "my_name": "Tom",
            ]
        ]
        
        let student = StudentModel.deserialize(from: dict)
        print("1111 \(String(describing: student))")
    }
    
    
    struct FlatModel: SmartCodableX {
        var _cover: String = "123"
    }
    struct StudentModel: SmartCodableX {
        var student: FlatModel?
    }
}
