//
//  MultilineStringTest.swift
//  SmartCodable
//
//  Created by Zero.D.Saber on 2025/10/11.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import SmartCodable
import Testing

private struct User: SmartCodable {
    var name: String = ""
    var age: Int = 0
}

struct MultilineStringTest {
    @Test("issue #116 test case")
    func decodeMultilingDictStr() {
        let jsonString1 = """
                            {
                                "name": "Sam",
                                "age": 22
                            }
                    """
        let user1 = User.deserialize(from: jsonString1)
        #expect(user1?.name == "Sam")
        #expect(user1?.age == 22)
        
        
        let jsonString2 = """
                        "name": "Zero",
                    "age": 100
                    
        """
        let user2 = User.deserialize(from: jsonString2)
        #expect(user2 == nil)
    }
    
    @Test("array case")
    func decodeMultilingArrayStr() {
        let jsonString = """
                    [
                        {
                            "name": "Zero",
                            "age": "99"
                        }
                    ]
                    """
        let users = [User].deserialize(from: jsonString)
        #expect(users?.first?.name == "Zero")
        #expect(users?.first?.age == 99)
    }
}
