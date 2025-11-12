//
//  Encode_SpecialData_colorViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit



class Encode_SpecialData_colorViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        
        let dict: [String: Any] = [
            "a": "ffffff",
        ]

        guard let adaptive = Model.deserialize(from: dict) else { return }
        
        smartPrint(value: adaptive)
        
        if let to = adaptive.toDictionary() {
            print(to)
        }
    }
}


extension Encode_SpecialData_colorViewController {
    struct Model: SmartCodable {
        @SmartHexColor
        var a: UIColor?
    }
}




