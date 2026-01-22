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
            "frinds": [
                "a": [],
                "b": "b",
                "c": NSNull(),
                "d": 1,
                "f": true
            ],
            "ages": ["a": 1, "b": 2, "c": "3","d": 4],
            "names": [ "name1": "Tim", "name2": 2, "name3": []]
        ]
        
        guard let student = Model.deserialize(from: dict) else { return }
        print("⭐️解析结果: frinds = \(student.frinds)")
        print("⭐️解析结果: ages = \(student.ages)")
        print("⭐️解析结果: names = \(student.names)")

    }
    
    struct Model: SmartDecodable {
        @SmartCompact.Dictionary
        var frinds: [String: Any] = [:]
        
        @SmartCompact.Dictionary
        var ages: [String: Int] = [:]
        
        @SmartCompact.Dictionary
        var names: [String: String] = [:]
    }
}
