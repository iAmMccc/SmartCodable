//
//  CaseOneViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/9/13.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit


class CaseOneViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let json = """
        {
            "player_name": "balabala Team",
            "age": 20,
            "native_Place": "shandong",
            "scoreInfo": {
                "gross_score": 2.4,
                "scores": [
                    0.9,
                    0.8,
                    0.7
                ],
                "remarks": {
                    "judgeOne": {
                        "content": "good"
                    },
                    "judgeTwo": {
                        "content": "very good"
                    },
                    "judgeThree": {
                        "content": "bad"
                    }
                }
            }
        }
        """
        
        guard let model = Player.deserialize(from: json) else { return }
        print(model)

        guard let dictJson = model.toJSONString(prettyPrint: true) else { return }
        print(dictJson)
        
        guard let model1 = Player.deserialize(from: dictJson) else { return }
        print(model1)
    }
}



struct Remark: SmartCodable {
    
    var judge: String = ""
    var content: String = ""
}

struct Player: SmartCodable {
    
    init() { }
    var name: String = ""
    var age: Int = 0
    var nativePlace: String = ""
    var grossScore: CGFloat = 0
    var scores: [CGFloat] = []
    var remarks: [Remark] = []
    
    // 当前容器中需要包含的key
    enum CodingKeys: String, CodingKey {
        case name = "player_name"
        case age
        case nativePlace = "native_Place"
        case scoreInfo
    }
   
    enum ScoreInfoCodingKeys: String, CodingKey {
        case grossScore = "gross_score"
        case scores
        case remarks
    }
    
    struct RemarkCodingKeys: CodingKey {
        var intValue: Int? {return nil}
        init?(intValue: Int) {return nil}
        var stringValue: String //json中的key
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        static let content = RemarkCodingKeys(stringValue: "content")!
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.age = try container.decode(Int.self, forKey: .age)
        self.nativePlace = try container.decode(String.self, forKey: .nativePlace)
        
        let scoresContainer = try container.nestedContainer(keyedBy: ScoreInfoCodingKeys.self, forKey: .scoreInfo)
        self.grossScore = try scoresContainer.decode(CGFloat.self, forKey: .grossScore)
        self.scores = try scoresContainer.decode([CGFloat].self, forKey: .scores)
        
        let remarksContainer = try scoresContainer.nestedContainer(keyedBy: RemarkCodingKeys.self, forKey: .remarks)
        
        var remarks: [Remark] = []
        for key in remarksContainer.allKeys { //key的类型就是映射规则的类型(Codingkeys)
            let judge = key.stringValue
//            print(key)
            /**
             RemarkCodingKeys(stringValue: "judgeTwo", intValue: nil)
             RemarkCodingKeys(stringValue: "judgeOne", intValue: nil)
             RemarkCodingKeys(stringValue: "judgeThree", intValue: nil)
             */
            let keyedContainer = try remarksContainer.nestedContainer(keyedBy: RemarkCodingKeys.self, forKey: key)
            let content = try keyedContainer.decode(String.self, forKey: .content)
            let remark = Remark(judge: judge, content: content)
            remarks.append(remark)
        }
        self.remarks = remarks
    }

    func encode(to encoder: Encoder) throws {
        // 1. 生成最外层的字典容器
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(nativePlace, forKey: .nativePlace)
        
        // 2. 生成scoreInfo字典容器
        var scoresContainer = container.nestedContainer(keyedBy: ScoreInfoCodingKeys.self, forKey: .scoreInfo)
        try scoresContainer.encode(grossScore, forKey: .grossScore)
        try scoresContainer.encode(scores, forKey: .scores)
        
        // 3. 生成remarks字典容器（模型中结构是数组，但是我们要生成字典结构）
        var remarksContainer = scoresContainer.nestedContainer(keyedBy: RemarkCodingKeys.self, forKey: .remarks)
        for remark in remarks {
            var remarkContainer = remarksContainer.nestedContainer(keyedBy: RemarkCodingKeys.self, forKey: RemarkCodingKeys(stringValue: remark.judge)!)
            try remarkContainer.encode(remark.content, forKey: .content)
        }
    }
}
