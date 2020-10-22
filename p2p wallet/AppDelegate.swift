//
//  AppDelegate.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window : UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Override point for customization after application launch.
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        self.window?.rootViewController = UINavigationController(rootViewController: ViewController())
        self.window?.makeKeyAndVisible()
        
        DispatchQueue.global(qos: .background).async {
            NodeRunner.startEngine(withArguments: ["node", "-e", "require('http').createServer((req, res) => res.end('alive!')).listen(3000);"])
        }
        
        return true
    }

}

