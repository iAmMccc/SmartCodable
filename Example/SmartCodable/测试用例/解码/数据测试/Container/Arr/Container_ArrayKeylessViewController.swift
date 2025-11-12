//
//  Container_ArrayKeylessViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/3/1.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import SmartCodableKit

class Container_ArrayKeylessViewController: BaseCompatibilityViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let dict = keylssJson.toDictionary() else { return }

        let keylessArr: [Any] = [dict]
        
        if let models = [CompatibleTypes].deserialize(from: keylessArr) {
            smartPrint(value: models.first)
        }
        
        
        if let models = [OptionalCompatibleTypes].deserialize(from: keylessArr) {
            smartPrint(value: models.first)
        }
        
    }

}
