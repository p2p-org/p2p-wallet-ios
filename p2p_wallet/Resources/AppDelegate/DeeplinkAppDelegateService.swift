//
//  DeeplinkAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import Resolver

final class DeeplinkAppDelegateService: NSObject, AppDelegateService {
    // MARK: - URIScheme

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard
            let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let host = components.host,
            let path = components.path,
            let params = components.queryItems
        else { return false }

        if
            Environment.current != .release,
            host == "onboarding",
            path == "/seedPhrase",
            let seedPhrase: String = params.first(where: { $0.name == "value" })?.value,
            let pincode: String = params.first(where: { $0.name == "pincode" })?.value
        {
            let userWalletManager: UserWalletManager = Resolver.resolve()
            let appEventHandler: AppEventHandlerType = Resolver.resolve()
            let pincodeStorageService: PincodeStorageType = Resolver.resolve()
            let authService: AuthenticationHandlerType = Resolver.resolve()
            Task {
                appEventHandler.delegate?.disablePincodeOnFirstAppear()
                pincodeStorageService.save(pincode)
                Defaults.isBiometryEnabled = false

                try await userWalletManager.add(seedPhrase: seedPhrase.components(separatedBy: "-"), derivablePath: .default, name: nil, deviceShare: nil, ethAddress: nil)

                try await Task.sleep(nanoseconds: 1_000_000_000)
                authService.authenticate(presentationStyle: nil)
            }
            return true
        }

        return false
    }
    
    // MARK: - Universal links
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if
            let webpageURL = userActivity.webpageURL,
            let urlComponents = URLComponents(url: webpageURL, resolvingAgainstBaseURL: true)
        {
            // Intercom survey
            if urlComponents.path == "/intercom",
               let queryItem = urlComponents.queryItems?.first(where: { $0.name == "intercom_survey_id" }),
               let value = queryItem.value
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    GlobalAppState.shared.surveyID = value
                }
                return true
            }
            
            // send via link
            else if webpageURL.host == "t.key.app" {
                GlobalAppState.shared.sendViaLinkUrl = webpageURL
                return true
            }
        }
        
        return false
    }
}
