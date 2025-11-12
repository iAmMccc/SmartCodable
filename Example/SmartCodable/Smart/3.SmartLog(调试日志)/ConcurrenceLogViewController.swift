//
//  ConcurrenceLogViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/5.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodable

class ConcurrenceLogViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict: [String: String] = [:]
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        let group = DispatchGroup()
        
        queue.async(group: group) {
            if let model = NewModel.deserialize(from: dict) {
                print(model)
            }
        }
        
        queue.async(group: group) {
            if let model = OldModel.deserialize(from: dict) {
                print(model)
            }
        }
        
        queue.async(group: group) {
            if let model = MiddleModel.deserialize(from: dict) {
                print(model)
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            print("Both methods are completed.")
        }
    }
    
    
    struct NewModel: SmartCodableX {
        var new_a: String = ""
        var new_bbbbb: String = ""
        var new_c: String = ""
        var new_d: String = ""
        var new_e: String = ""
        var new_f: String = ""
    }



    struct OldModel: SmartCodableX {
        var old_a: String = ""
        var old_bbbbb: String = ""
        var old_c: String = ""
        var old_d: String = ""
        var old_e: String = ""
        var old_f: String = ""
    }



    struct MiddleModel: SmartCodableX {
        var middle_a: String = ""
        var middle_b: String = ""
        var middle_c: String = ""
        var middle_d: String = ""
        var middle_e: String = ""
        var middle_f: String = ""
    }

}


