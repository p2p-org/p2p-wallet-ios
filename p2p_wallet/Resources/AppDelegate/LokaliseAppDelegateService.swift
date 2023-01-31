//
//  LokaliseAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import Lokalise

final class LokaliseAppDelegateService: NSObject, AppDelegateService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Lokalise.shared.setProjectID(
            String.secretConfig("LOKALISE_PROJECT_ID")!,
            token: String.secretConfig("LOKALISE_TOKEN")!
        )
        Lokalise.shared.swizzleMainBundle()
        
        return true
    }
}
