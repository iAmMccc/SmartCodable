//
//  BaseCompatibilityViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/5.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

class BaseCompatibilityViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}

extension BaseCompatibilityViewController {
    var keylssJson: String {
               """
               {
               
               }
               """
    }
    
    
    var typeMissmatchJson: String {
               """
               {
                 "a": [],
                 "b": [],
                 "c": [],
                 "d": [],
               
                 "e": [],
                 "f": [],
                 "g": [],
               
                 "h": [],
                 "i": [],
                 "j": [],
                 "k": [],
                 "l": [],

                 "m": [],
                 "n": [],
                 "o": [],
                 "p": [],
                 "q": [],
                
                 "r": [],
               
               
                 "v": 123,
                 "w": 123,
                 "x": 123,
                 "y": 123,
                 "z": 123,
               }
               """
    }
    
    
    var nullJson: String {
               """
               {
                 "a": null,
                 "b": null,
                 "c": null,
                 "d": null,
                 "e": null,
                 "f": null,
                 "g": null,
                 "h": null,
                 "i": null,
                 "j": null,
                 "k": null,
                 "l": null,
               
               
                 "m": null,
                 "n": null,
                 "o": null,
                 "p": null,
                 "q": null,
                
                 "r": null,
               
                 "v": null,
                 "w": null,
                 "x": null,
                 "y": null,
                 "z": null,
               }
               """
    }
    
    var emptyObjectJson: String {
               """
               {
                 "v": [],
                 "w": {},
                 "x": {},
                 "y": {},
                 "z": {},
               }
               """
    }
        
}



struct CompatibleTypes: SmartDecodable {

    var a: String = ""
    var b: Bool = false
    var c: Date = Date()
    var d: Data = Data()

    var e: Double = 0.0
    var f: Float = 0.0
    var g: CGFloat = 0.0

    var h: Int = 0
    var i: Int8 = 0
    var j: Int16 = 0
    var k: Int32 = 0
    var l: Int64 = 0

    var m: UInt = 0
    var n: UInt8 = 0
    var o: UInt16 = 0
    var p: UInt32 = 0
    var q: UInt64 = 0
    
    // URL无法提供默认值
//    var r: URL = URL(string: "www.baidu.com")!
    

    var v: [String] = []
    var w: [String: [String: Int]] = [:]
    var x: [String: String] = [:]
    var y: [String: Int] = [:]
    var z: CompatibleItem = CompatibleItem()
}


class CompatibleItem: SmartDecodable {
    var name: String = ""
    var age: Int = 0
    
    required init() { }
}

// ==== 可选情况
struct OptionalCompatibleTypes: SmartDecodable {
    init() { }

    var a: String?
    var b: Bool?
    var c: Date?
    var d: Data?

    var e: Double?
    var f: Float?
    var g: CGFloat?

    var h: Int?
    var i: Int8?
    var j: Int16?
    var k: Int32?
    var l: Int64?

    var m: UInt?
    var n: UInt8?
    var o: UInt16?
    var p: UInt32?
    var q: UInt64?
    
    var r: URL?

    var v: [String]?
    var w: [String: [String: Int]]?
    var x: [String: String]?
    var y: [String: Int]?

    var z: CompatibleItem?
}

var typeMissmatchJson: String {
           """
           {
           "a": [],
           "b": [],
           "c": [],
           "d": [],
           "e": [],
           "f": [],
            "g": [],
            "h": [],
            "i": [],
            "j": [],
            "k": [],
            "l": [],
           "m": [],
           "n": [],
           "o": [],
           "p": [],
           "q": [],
                    
         
           
            "v": 123,
            "w": 123,
            "x": 123,
            "y": 123,
            "z": 123,
          }
         """
}
