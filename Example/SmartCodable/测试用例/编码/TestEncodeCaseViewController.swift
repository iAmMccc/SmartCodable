//
//  TestEncodeCaseViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2024/6/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

import UIKit

class TestEncodeCaseViewController: BaseViewController {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "编码测试用例"
        
       
        
        dataArray = [
            testCaseOne,
            testCaseTwo,
            testCaseThree,
        ]
        
        
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.reloadData()
    }
    var dataArray: [[String: Any]] = []

    lazy var tableView = UITableView.make(registerCells: [UITableViewCell.self], delegate: self, style: .grouped)

}



extension TestEncodeCaseViewController {
    
    var testCaseOne: [String: Any] {
        [
            "title": "CaseOne - 基础数据测试",
            "list": [
                ["name": "String的自定义解析",     "vc": "Encode_BaseData_StringViewController"],
                ["name": "Bool的自定义解析",       "vc": "Encode_BaseData_BoolViewController"],
                ["name": "Int系列的自定义解析",     "vc": "Encode_BaseData_IntViewController"],
                ["name": "Float系列的自定义解析",   "vc": "Encode_BaseData_FloatiewController"],
            ]
        ]
    }
    
    var testCaseTwo: [String: Any] {
        [
            "title": "CaseOne - 特殊数据测试",
            "list": [
                ["name": "Date",                 "vc": "Encode_SpecialData_dateViewController"],
                ["name": "Data",                 "vc": "Encode_SpecialData_dataViewController"],
                ["name": "Color",                "vc": "Encode_SpecialData_colorViewController"],
                ["name": "URL",                  "vc": "Encode_SpecialData_urlViewController"],
                ["name": "Enum",                 "vc": "Encode_SpecialData_enumViewController"],
                ["name": "SmartAny",             "vc": "Encode_SpecialData_anyViewController"],
                ["name": "嵌套模型",               "vc": "Encode_SpecialData_modelViewController"],
            ]
        ]
    }
    
    var testCaseThree: [String: Any] {
        [
            "title": "CaseOne - 自定义行为的影响",
            "list": [
                ["name": "通过CodingKeys",     "vc": "Encode_CustomKeyViewController"],
                ["name": "通过mappingForKey",  "vc": "Encode_CustomKeyViewController"],
                ["name": "SmartIgnored",         "vc": "Encode_IgnoredKeyViewController"],
            ]
        ]
    }

}




extension TestEncodeCaseViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        
        present(vc, animated: true)
    }
    
}




extension TestEncodeCaseViewController {
    
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
