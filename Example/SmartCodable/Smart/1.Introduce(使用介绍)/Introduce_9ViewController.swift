//
//  Introduce_9ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/4/10.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit


class Introduce_9ViewController: BaseCompatibilityViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
    
        let dict = [
            "color": "7DA5E3"
        ]
        
        guard let model = Model.deserialize(from: dict) else { return }
        print(model.color as Any)
        
        let trans = model.toDictionary()
        print(trans)
    }
}

extension Introduce_9ViewController {
    struct Model: SmartCodable {
        @SmartHexColor(encodeHexFormat: .rrggbbaa(.hash))
        var color: UIColor? = .white
    }
}



