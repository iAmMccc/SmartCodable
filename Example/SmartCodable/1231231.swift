//
//  1231231.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/9/26.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import SmartCodable

class MyModel: ObservableObject, SmartCodableX {
    required init() {
        
    }
    @Published 
    var name: String = "iOS Developer"
    
    enum CodingKeys: String, CodingKey {
        case name
    }
    
    // 自定义的编码方法
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }

    // 自定义的解码方法
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }

}

//struct ContentView: View {
//    @ObservedObject var model = MyModel()
//
//    var body: some View {
//        VStack {
//            Text("Hello, \(model.name)")
//            Button("Change Name") {
//                model.name = "Swift Developer"
//            }
//        }
//    }
//}
