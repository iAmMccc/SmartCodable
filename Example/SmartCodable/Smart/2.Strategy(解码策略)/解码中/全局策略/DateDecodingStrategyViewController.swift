//
//  DateDecodingStrategy.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/11/30.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

class DateDecodingStrategyViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        let json = """
        {
           "birth": "2034-12-01 18:00:00",
           "birth1": "2024-12-01 18:00:00"

        }
        """
        let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let option: SmartDecodingOption = .date(.formatted(dateFormatter))
        guard let model = FeedOne.deserialize(from: json, options: [option]) else { return }
        print(model)
        
        
    }
}



extension DateDecodingStrategyViewController {

    struct FeedOne: SmartCodable {
        
        var birth: Date = Date()
        var birth1: String = ""
    }
}




