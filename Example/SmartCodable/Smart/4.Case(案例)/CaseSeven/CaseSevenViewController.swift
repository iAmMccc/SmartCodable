//
//  CaseSevenViewController.swift
//  SmartCodable_Example
//
//  Created by Mccc on 2023/8/8.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SmartCodableKit

// 兼容 解析失败的情况。 

/** 整体性测试
 * 1. 演示多定义字段的情况
 * 2. 演示数据多字段的情况
 * 3. 演示数据为空的情况
 * 4. 演示数据类型与定义类型不一致的情况
 */

class CaseSevenViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        reauestData()
        
        /** 复杂数据结构的演示
         * 1. 演示数据多字段的情况
         * 2. 演示数据为空的情况
         * 3. 演示数据类型与定义类型不一致的情况
         */
        
        

    }
    
    
    var dataArray: [Class] = []
    
    lazy var tableView = UITableView.make(registerCells: [ComplexDataStructureDetailCell.self], registerHeaders: [ComplexDataStructureSectionHeader.self], registerFooters: [ComplexDataStructureSectionHeader.self], delegate: self, style: .grouped)
}

extension CaseSevenViewController {
    func reauestData() {
        
        let classArrayJson = """
        [
          {
            "redundant": "多余的数据",
            "name" : "高三1班",
            "number" : 25,
            "students" : [
              {
                "id" : 1,
                "sex" : "男",
                "name" : "大黄",
                "area" : "山东",
              },
              {
                "id" : 2,
                "sex" : "未知",
                "name" :  2,
                "area" : {},
               }
            ]
          },
          {
            "name" : "高三2班",
            "number" : "30",
            "students" : [
              {
                "id" : "1",
                "sex" : "男",
                "name" : 123,
                "area" : "山东",
              },
              {
                "id" : 2,
                "sex" : "未知",
                "name" :  2,
                "area" : false,
               }
            ]
          }
        ]
        """

        let arr = classArrayJson.toArray() ?? []
        
        
        var endArr: [Any] = []
        
        for _ in 0...0 {
            
            for item in arr {
                endArr.append(item)
            }
        }
        
        
        
        
        guard let models = [Class].deserialize(from: endArr) else { return }
        dataArray = models
        tableView.reloadData()
    }
}

extension CaseSevenViewController {
    func initUI() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}





extension CaseSevenViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.makeSectionHeader(ComplexDataStructureSectionHeader.self)
        if let classModel = dataArray[section~] {
            header.model = classModel
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = tableView.makeSectionFooter(ComplexDataStructureSectionFooter.self)
        return footer
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let classModel = dataArray[section~] {
            return classModel.students.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ComplexDataStructureDetailCell = tableView.makeCell(indexPath: indexPath)
        if let classModel = dataArray[indexPath.section~] {
            if let student = classModel.students[indexPath.row~] {
                cell.model = student
            }
        }
        return cell
    }
}



