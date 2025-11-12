//
//  ViewController.swift
//  SmartCodable
//
//  Created by Mccc on 08/08/2023.
//  Copyright (c) 2023 Mccc. All rights reserved.
//

import UIKit
import SmartCodableKit

class ViewController: UIViewController {
    
    
    var dataArray: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SmartCodable"
        
        dataArray = [
            other,
            smart_introduce,
            smart_test,
            replace_HandyJSON,
            smart_customDecoding,
            smart_debug,
            smart_case,
        ]
        
        
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.reloadData()
    }
    
    lazy var tableView = UITableView.make(registerCells: [UITableViewCell.self], delegate: self, style: .grouped)
}


extension ViewController {
    
    var smart_test: [String: Any] {
        [
            "title": "测试用例",
            "list": [
                ["name": "解码测试用例 >>>", "vc": "TestDecodeCaseViewController"],
                ["name": "编码测试用例 >>>", "vc": "TestEncodeCaseViewController"],
                ["name": "继承测试用例 >>>", "vc": "TestInheritCaseViewController"],
            ]
        ]
    }
    
    
    var replace_HandyJSON: [String: Any] {
        [
            "title": "替换HandyJSON",
            "list": [
                ["name": "替换HandyJSON的工作量 >>>", "vc": "ReplaceHandyJSONViewController"],
            ]
        ]
    }
    
    
    var smart_introduce: [String: Any] {
        [
            "title": "Smart使用介绍",
            "list": [
                ["name": "使用介绍, 快速的了解SmartCodable >>>",       "vc": "IntroduceViewController"],
            ]
        ]
    }
    
    
    var smart_customDecoding: [String: Any] {
        [
            "title": "Smart的解码策略",
            "list": [
                ["name": "解码策略(解码前，解码中，解码后) >>>", "vc": "DecodingStrategyViewController"],
            ]
        ]
    }


    
    var smart_debug: [String: Any] {
        [
            "title": "Smart调试信息",
            "list": [
                ["name": "日志自定义", "vc": "DecodingLogViewController"],
                ["name": "字典日志", "vc": "DecodingDictLogViewController"],
                ["name": "数组日志", "vc": "DecodingArrayLogViewController"],
                ["name": "并发日志", "vc": "ConcurrenceLogViewController"],

            ]
        ]
    }
    
    var smart_case: [String: Any] {
        [
            "title": "Smart案例",
            "list": [
                ["name": "扁平化", "vc": "CaseOneViewController"],
                ["name": "Model继承", "vc": "CaseTwoViewController"],
                ["name": "多值映射", "vc": "CaseThreeViewController"],
                ["name": "范型解析", "vc": "CaseFourViewController"],
                ["name": "范型解析 - signle value", "vc": "CaseFiveViewController"],
                ["name": "复杂场景的解析", "vc": "CaseSixViewController"],
                ["name": "复杂场景的解析2", "vc": "CaseSevenViewController"],
                ["name": "类型分发解析场景", "vc": "CaseEightViewController"],
            ]
        ]
    }
    
    
    var other: [String: Any] {
        [
            "title": "内部测试（请忽略）",
            "list": [
                ["name": "测试代码1", "vc": "TestViewController"],
                ["name": "测试代码2", "vc": "Test2ViewController"],
                ["name": "测试代码3", "vc": "Test3ViewController"],

            ]
        ]
    }
}




extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let dict = dataArray[section~] {
            let list = dict["list"] as? [[String: String]] ?? []
            return list.count
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        if let dict = dataArray[section~] {
            let title = dict["title"] as? String ?? ""
            label.text = "    " + title
        }
        
        return label
    }

    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.makeCell(indexPath: indexPath)
        
        if let dict = dataArray[indexPath.section~] {

            let list = dict["list"] as? [[String: String]] ?? []
            
            let inDict = list[indexPath.row~] ?? [:]
            cell.textLabel?.text = inDict["name"] ?? ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        guard let dict = dataArray[indexPath.section~] else { return }
        guard let list = dict["list"] as? [[String: String]] else { return }
        guard let inDict = list[indexPath.row~] else { return }

        let vcStr = inDict["vc"] ?? ""
        let name = inDict["name"] ?? ""
        guard let vc = createViewControllerObject(form: vcStr) else { return }
        vc.contentText = name
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
}



extension ViewController {
    
    func createViewControllerObject(form className: String) -> BaseViewController? {
        let projectName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
        let classStringName = projectName + "." + className
        if let viewControllerClass = NSClassFromString(classStringName) as? BaseViewController.Type {
            let viewController = viewControllerClass.init()
            return viewController
        } else {
            return nil
        }
    }
}
