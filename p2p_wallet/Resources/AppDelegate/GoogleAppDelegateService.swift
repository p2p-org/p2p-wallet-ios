//
//  GoogleAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Firebase
import Foundation
import GoogleSignIn

final class GoogleAppDelegateService: NSObject, AppDelegateService {
    override init() {
        super.init()

        var arguments = ProcessInfo.processInfo.arguments
        #if !RELEASE
        arguments.removeAll { $0 == "-FIRDebugDisabled" }
        arguments.append("-FIRDebugEnabled")
        #else
        arguments.removeAll { $0 == "-FIRDebugEnabled" }
        arguments.append("-FIRDebugDisabled")
        #endif
        ProcessInfo.processInfo.setValue(arguments, forKey: "arguments")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
