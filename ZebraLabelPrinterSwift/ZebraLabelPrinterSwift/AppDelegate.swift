//
//  AppDelegate.swift
//  ZebraLabelPrinterSwift
//
//  Created by Sachin Pampannavar on 12/10/19.
//  Copyright © 2019 Sachin Pampannavar. All rights reserved.
//

import UIKit
import ZebraMultiOSLabelPrinterSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        
        let printLabelController = PrintLabelController(style: .grouped)
        let rootController = UINavigationController(rootViewController: printLabelController)
        window?.rootViewController = rootController
        
        
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        ZebraMultiOSLabelPrinterSwift.shared.closeConnectionToPrinter()
    }


}

