//
//  SpecialData_ColorViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/5/22.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit


class SpecialData_ColorViewController: BaseCompatibilityViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
    
        let dict: [String: Any] = [
            "color2": NSNull(),
            "color3": "VVVVVV", // bad color hex
            "color4": "7DA5E3"
        ]
        
        guard let model = Model.deserialize(from: dict) else { return }
        smartPrint(value: model)

        
        let trans = model.toDictionary()
        print(trans as Any)

    }
}


extension SpecialData_ColorViewController {
    struct Model: SmartCodable {
        @SmartHexColor
        var color1: UIColor?
        @SmartHexColor
        var color2: UIColor?
        @SmartHexColor(encodeHexFormat: .rgb(.none))
        var color3: UIColor? = .yellow
        @SmartHexColor
        var color4: UIColor? = .red
    }
}



