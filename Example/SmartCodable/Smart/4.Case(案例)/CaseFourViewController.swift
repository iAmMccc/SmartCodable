//
//  CaseFourViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/11/22.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable




class CaseFourViewController : BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let dict = [
            "code": 1,
            "timeStamp": 2,
            "message": "error",
            "data": [
                "name": "xiaoming"
            ]
        ] as [String : Any]
 
        let model = ApiCommon<SomeDataModel>.deserialize(from: dict)
        print(model?.data?.name ?? "")
    }
}



extension CaseFourViewController {
    struct SomeDataModel: SmartCodableX {
        var name: String?
    }


    struct ApiCommon<Element: SmartCodableX>: SmartCodableX {
        public var data: Element?
        public var code: Int?
        public var timeStamp: Int?
        public var message: String?
    }

}

