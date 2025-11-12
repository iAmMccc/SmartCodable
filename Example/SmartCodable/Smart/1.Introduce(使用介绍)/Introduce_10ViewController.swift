//
//  Introduce_10ViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/4/30.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit
import HandyJSON



class Introduce_10ViewController: BaseViewController {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        testDeserializeNestedStructure()
        
        test2()
    }
}


extension Introduce_10ViewController {
    func test() {
        
        let jsonArrayString: String? = "{\"result\":{\"data\":[{\"name\":\"Bob\",\"id\":\"1\",\"height\":180},{\"name\":\"Lily\",\"id\":\"2\",\"height\":150},{\"name\":\"Lucy\",\"id\":\"3\",\"height\":160}]}}"

        let data = jsonArrayString?.data(using: .utf8)

        guard let models = [Family].deserialize(from: data, designatedPath: "result.data") else { return }
        print(models)
    }
    
    struct Family: SmartCodable {
        
        var name: String?
        var id: String?
        var height: Int?
    }
}

extension Introduce_10ViewController {
    func test2() {
        
        let jsonString = "{\"data\":{\"result\":{\"id\":123456,\"arr1\":[1,2,3,4,5,6],\"arr2\":[\"a\",\"b\",\"c\",\"d\",\"e\"]}},\"code\":200}"

        let data = jsonString.data(using: .utf8)

        guard let models = Home.deserialize(from: data, designatedPath: "data.result") else { return }
        print(models)
    }
    
    struct Home: SmartCodable {
        
        @SmartAny
        var arr1: [Any]?
        var id: String?
        var arr2: [String]?
    }
}


extension Introduce_10ViewController {
    func testDeserializeArrayPath() {
        let jsonString = """
            {
                "people": [
                    {
                        "name": "John Doe",
                        "age": 30
                    },
                    {
                        "name": "Jane Smith",
                        "age": 25
                    }
                ]
            }
            """
        
        if let models = [PathModel].deserialize(from: jsonString, designatedPath: "people") {
          print(models)
        }
    }
    
    func testDeserializeNestedArrayPath() {
        let jsonString = """
            {
                "person": {
                    "name": "John Doe",
                    "friends": [
                        {
                            "name": "Alice",
                            "age": 25
                        },
                        {
                            "name": "Bob",
                            "age": 28
                        }
                    ]
                }
            }
            """
        
        if let model = NestedArrayModel.deserialize(from: jsonString, designatedPath: "person") {
            print(model)
        }
    }
    
    func testDeserializeInvalidPath() {
        let jsonString = """
            {
                "person": {
                    "name": "John Doe",
                    "age": 30
                }
            }
            """
        
        if let model = PathModel.deserialize(from: jsonString, designatedPath: "invalid.path") {
            print(model)
        }
    }
    
    func testDeserializeEmptyPath() {
        let jsonString = """
            {
                "name": "John Doe",
                "age": 30
            }
            """
        
        if let model = PathModel.deserialize(from: jsonString, designatedPath: "") {
            print(model)
        }
    }
    
    func testDeserializeArrayWithPath() {
        let jsonString = """
            {
                "data": {
                    "names": ["Alice", "Bob", "Charlie"]
                }
            }
            """
        
        if let models = [PathArrayModel].deserialize(from: jsonString, designatedPath: "data.names") {
            print(models)
        }
    }
    
    func testDeserializeNestedStructure() {
        let jsonString = """
            {
              "code": 200,
              "message": "Success",
              "data": {
                "school": {
                  "name": "ABC University",
                  "departments": [
                    {
                      "name": "Computer Science",
                      "courses": [
                        {
                          "code": "CS101",
                          "title": "Introduction to Computer Science"
                        },
                        {
                          "code": "CS201",
                          "title": "Data Structures and Algorithms"
                        }
                      ]
                    },
                    {
                      "name": "Mathematics",
                      "courses": [
                        {
                          "code": "MATH101",
                          "title": "Calculus I"
                        },
                        {
                          "code": "MATH201",
                          "title": "Linear Algebra"
                        }
                      ]
                    }
                  ]
                }
              }
            }
            """
        
        if let school = School.deserialize(from: jsonString, designatedPath: "data.school") {
            print(school)
        }
        guard let departments = [Department].deserialize(from: jsonString, designatedPath: "data.school.departments") else {
            return
        }
        print(departments)
        
    }
    
    
    
    struct PathModel: SmartCodable {
        var name: String?
        var age: Int?
    }
    
    struct NestedArrayModel: SmartCodable {
        var name: String?
        var friends: [Friend]?
        
        struct Friend: SmartCodable {
            var name: String = ""
            var age: Int = 0
        }
    }
    
    struct PathArrayModel: SmartCodable {
        var name: [String]?
    }
    
    struct Course: SmartCodable {
        var code: String?
        var title: String?
    }
    
    struct Department: SmartCodable {
        var name: String?
        var courses: [Course]?
    }
    
    struct School: SmartCodable {
        var name: String?
        var departments: [Department]?
    }
}

