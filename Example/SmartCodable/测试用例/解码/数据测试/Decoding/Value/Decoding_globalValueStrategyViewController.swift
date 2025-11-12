//
//  Decoding_globalValueStrategyViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/5/30.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

class Decoding_globalValueStrategyViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataStrategy()
        dateStrategy()
    }
}


extension Decoding_globalValueStrategyViewController {
    func dataStrategy() {
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
    
    struct FeedOne: SmartCodable {
        var address: Data?
    }
}

extension Decoding_globalValueStrategyViewController {
    func dateStrategy() {
        let json = """
        {
           "birth": "2034-12-01 18:00:00",
           "birth1": "2024-12-01 18:00:00"

        }
        """
        let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let option: SmartDecodingOption = .date(.formatted(dateFormatter))
        guard let model = FeedTwo.deserialize(from: json, options: [option]) else { return }
        smartPrint(value: model)
    }
    
    struct FeedTwo: SmartCodable {
        
        var birth: Date = Date()
        var birth1: String = ""
    }
}
