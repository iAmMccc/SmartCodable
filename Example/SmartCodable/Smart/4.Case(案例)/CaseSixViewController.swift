//
//  CaseSixViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/8/14.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SmartCodableKit


/// 数据结构不同的处理
class CaseSixViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     
        
        let jsonStr = """
        {
            "1" : {
                "name" : "xiaoming"
            },
            "2" : {
                "name" : "dahuang"
            },
            "3" : {
                "name" : "zhanghua"
            }
        }
        """
        guard let stuList2 = jsonStr.decode(type: BaseStudentList.self) else { return }
        print(stuList2)
        
        
    
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(stuList2) else { return }
        guard let value = String(data: data, encoding: .utf8) else { return }
        print(value)

        
        let dict = [
            "grade": "13班",
            "students": [
                "xiaoming": 89,
                "xiaoli": 60,
                "lihua": 100
            ]
        ] as [String : Any]
        
        
        /** 与使用非常不同的结构的JSON API兼容
         
         
         Model
         - grade: String
         - scores [ExchangeScore]
          - grade
          - name
          - score
         
         */
        
        
        guard let model = dict.decode(type: GradeScores.self) else { return }
        print(model)
    }
}



struct GradeScores: Codable {
    var grade: String
    
    // 在对值进行编码或解码时，永远不会考虑计算属性。
    var exchangeScores: [StudentScore] {
        return students.values
    }
    
    //
    private var students: StudentScore.List
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.grade = try container.decode(String.self, forKey: .grade)
        self.students = try container.decode(StudentScore.List.self, forKey: .students)
        
        
        var values: [StudentScore] = []
        
        for item in self.students.values {
            var temp = item
            temp.grade = self.grade
            values.append(temp)
        }
        
        self.students.values = values
    }
    
    
}

// [ "xiaoming": 89] 将这样的数据转成模型
struct StudentScore: Codable {
    var grade: String
    let name: String
    let score: Double
}


private extension StudentScore {
    struct List: Codable {
        var values: [StudentScore]

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let dictionary = try container.decode([String : Double].self)

            values = dictionary.map { key, value in
                StudentScore(grade: "", name: key, score: value)
            }
        }
    }
}





/// ==========  复杂结构
struct BaseStudent: Codable {
    let id: Int
    let name: String
}

struct BaseStudentList: Codable {
    var students: [BaseStudent] = []
    

    
    struct Codingkeys: CodingKey {
        var intValue: Int? {return nil}
        init?(intValue: Int) {return nil}
        var stringValue: String //json中的key
        // 根据key来创建Codingkeys，来读取key中的值
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        // 相当于enum中的case
        // 其实就是读取key是name所应对的值
        static let name = Codingkeys(stringValue: "name")!
    }
    
    init(from decoder: Decoder) throws {
        // 指定映射规则
        let container = try decoder.container(keyedBy: Codingkeys.self)
        
        var students: [BaseStudent] = []
        
        for key in container.allKeys { //key的类型就是映射规则的类型(Codingkeys)
            
            print(key)
            
            if let id = Int(key.stringValue) { // 首先读取key本身的内容
                
                // 在Swift中，nestedContainer是一个方法，用于在现有容器内创建一个新的容器。
                // 它通常用于处理嵌套的数据结构，比如字典或数组。通过使用nestedContainer，你可以访问和修改嵌套容器中的值。
                // 创建内嵌的keyedContainer读取key对应的字典，映射规则同样是Codingkeys
                let keyedContainer = try container.nestedContainer(keyedBy: Codingkeys.self, forKey: key)
                let name = try keyedContainer.decode(String.self, forKey: .name)
                let stu = BaseStudent(id: id, name: name)
                students.append(stu)
            }
        }
        self.students = students
    }
    
    func encode(to encoder: Encoder) throws {
         // 指定映射规则
         var container = encoder.container(keyedBy: Codingkeys.self)
         try students.forEach { stu in
             // 用Student的id作为key，然后该key对应的值是一个字典，所以我们创建一个处理字典的子容器
             var keyedContainer = container.nestedContainer(keyedBy: Codingkeys.self, forKey: Codingkeys(stringValue: "\(stu.id)")!)
             try keyedContainer.encode(stu.name, forKey: .name)
         }
     }
}

