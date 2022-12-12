//
//  AppsFlyerProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import AppsFlyerLib
import Foundation

final class AppsFlyerProvider: NSObject, AnalyticsProvider {
    init(appsFlyerDevKey: String, appleAppID: String) {
        #if DEBUG
            AppsFlyerLib.shared().isDebug = true
        #endif
        
        AppsFlyerLib.shared().appsFlyerDevKey = appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = appleAppID
        
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)

        super.init()

        AppsFlyerLib.shared().deepLinkDelegate = self
    }

    func logEvent(_ event: NewAnalyticsEvent) {
        AppsFlyerLib.shared().logEvent(
            name: event.name,
            values: event.parameters,
            completionHandler: { (response: [String : Any]?, error: Error?) in
                if let response = response {
                    print("In app event callback Success: ", response)
                }
                if let error = error {
                    print("In app event callback ERROR:", error)
                }
            }
        )
    }
}

// MARK: - DeepLinkDelegate

extension AppsFlyerProvider: DeepLinkDelegate {
    func didResolveDeepLink(_: DeepLinkResult) {}
}
