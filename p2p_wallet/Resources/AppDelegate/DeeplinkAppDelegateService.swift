//
//  DeeplinkAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import Resolver
import AppsFlyerLib
import Deeplinking

final class DeeplinkAppDelegateService: NSObject, AppDelegateService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AppsFlyerLib.shared().deepLinkDelegate = self
//        AppsFlyerLib.shared().appInviteOneLinkID = "sHgH"
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handler by Appflyer?
//            AppsFlyerLib.shared().handleOpen(url, options: options)
//            return true
        
        // Handler natively
        return Resolver.resolve(DeeplinkingRouter.self)
            .handleURIScheme(url: url)
        
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // get url components
        guard let webpageURL = userActivity.webpageURL
        else {
            return false
        }
        
        return Resolver.resolve(DeeplinkingRouter.self)
            .handleUniversalLink(url: webpageURL)
    }
}

// MARK: - AppFlyer's DeepLinkDelegate

extension DeeplinkAppDelegateService: DeepLinkDelegate {
    func didResolveDeepLink(_ result: DeepLinkResult) {}
}
