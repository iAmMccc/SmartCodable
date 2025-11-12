//
//  AppDelegate.swift
//  SmartCodable
//
//  Created by Mccc on 08/23/2023.
//  Copyright (c) 2023 Mccc. All rights reserved.
//

import UIKit
import SmartCodableKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
        SmartSentinel.debugMode = .verbose
        SmartSentinel.onLogGenerated { logs in
//            print(logs)
            // 解析的日志， 可以用来上传服务器
        }
        
        
        
        initRootViewController()
        
        

        return true
    }
}


extension AppDelegate {
    private func initRootViewController() {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white
        
        let vc = ViewController()
        let nav = UINavigationController.init(rootViewController: vc)
        window?.rootViewController = nav
//        window?.rootViewController = vc
        
        window?.makeKeyAndVisible()
    }
}

