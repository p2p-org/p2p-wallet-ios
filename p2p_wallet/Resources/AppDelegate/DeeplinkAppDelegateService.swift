//
//  DeeplinkAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import Resolver
import AppsFlyerLib

final class DeeplinkAppDelegateService: NSObject, AppDelegateService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AppsFlyerLib.shared().deepLinkDelegate = self
        AppsFlyerLib.shared().appInviteOneLinkID = "sHgH"
        return true
    }
    
    // MARK: - URIScheme

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard
            let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let host = components.host,
            let path = components.path
        else { return false }
        
        if
            Environment.current != .release,
            host == "onboarding",
            path == "/seedPhrase",
            let params = components.queryItems,
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
        }
        
        else if host == "t" {
            let seed = String(path.dropFirst())
            GlobalAppState.shared.sendViaLinkUrl = urlFromSeed(seed)
            return true
        }

        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }
    
    // MARK: - Universal links
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }
}

// MARK: - AppFlyer's DeepLinkDelegate
extension DeeplinkAppDelegateService: DeepLinkDelegate {
    func didResolveDeepLink(_ result: DeepLinkResult) {
        // get seed
        var seed: String?
        switch result.status {
        case .notFound:
            NSLog("[AFSDK] Deep link not found")
            return
        case .failure:
            print("Error %@", result.error!)
            return
        case .found:
            NSLog("[AFSDK] Deep link found")
        }
        
        guard let deepLinkObj = result.deepLink else {
            NSLog("[AFSDK] Could not extract deep link object")
            return
        }
        
        let deepLinkStr = deepLinkObj.toString()
        NSLog("[AFSDK] DeepLink data is: \(deepLinkStr)")
        
        // handle link
        if let urlString = deepLinkObj.clickEvent["link"] as? String,
           let urlComponents = URLComponents(string: urlString)
        {
            // Intercom survey
            if urlComponents.path == "/intercom",
               let queryItem = urlComponents.queryItems?.first(where: { $0.name == "intercom_survey_id" }),
               let value = queryItem.value
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    GlobalAppState.shared.surveyID = value
                }
            }
            
            // send via link
            else if urlComponents.host == "t.key.app" {
                GlobalAppState.shared.sendViaLinkUrl = urlComponents.url
            }
            return
        }
        
        if( deepLinkObj.isDeferred == true) {
            NSLog("[AFSDK] This is a deferred deep link")
        }
        else {
            NSLog("[AFSDK] This is a direct deep link")
        }
        
        seed = deepLinkObj.deeplinkValue
        GlobalAppState.shared.sendViaLinkUrl = urlFromSeed(seed)
    }
}

// MARK: - Helpers

private func urlFromSeed(_ seed: String?) -> URL? {
    guard let seed else { return nil }
    var urlComponent = URLComponents()
    urlComponent.scheme = "https"
    urlComponent.host = "t.key.app"
    urlComponent.path = "/\(seed)"
    return urlComponent.url
}
