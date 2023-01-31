//
//  DeeplinkAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import Intercom

final class IntercomAppDelegateService: NSObject, AppDelegateService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        IntercomStartingConfigurator().configure()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Intercom.setDeviceToken(deviceToken) { error in
            guard let error else { return }
            print("Intercom.setDeviceToken error: ", error)
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Handle intercom deeplink
        if
            let webpageURL = userActivity.webpageURL,
            let urlComponents = URLComponents(url: webpageURL, resolvingAgainstBaseURL: true)
        {
            if urlComponents.path == "/intercom" {
                if
                    let queryItem = urlComponents.queryItems?.first(where: { $0.name == "intercom_survey_id" }),
                    let value = queryItem.value
                {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        GlobalAppState.shared.surveyID = value
                    }
                    return true
                }
            }
        }

        return false
    }
}
