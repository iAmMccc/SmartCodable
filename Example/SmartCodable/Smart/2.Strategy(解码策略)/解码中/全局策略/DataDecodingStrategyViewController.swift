//
//  DataDecodingStrategy.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/11/30.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable

class DataDecodingStrategyViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let json = """
        {
           "address": "aHR0cHM6Ly93d3cucWl4aW4uY29t"
        }
        """
        
        let option: SmartDecodingOption = .data(.base64)
        guard let model = FeedOne.deserialize(from: json, options: [option]) else { return }
        
        if let data = model.address, let url = String(data: data, encoding: .utf8) {
            print(url)
            // https://www.qixin.com
        }
    }
}



extension DataDecodingStrategyViewController {

    struct FeedOne: SmartCodableX {
        var address: Data?
    }
}
