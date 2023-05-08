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
//        AppsFlyerLib.shared().appInviteOneLinkID = "sHgH"
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handler by Appflyer?
//            AppsFlyerLib.shared().handleOpen(url, options: options)
//            return true
        
        // Handler natively
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else { return false }
        
        handleCustomURIScheme(urlComponents: components)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // get url components
        guard
            let webpageURL = userActivity.webpageURL,
            let urlComponents = URLComponents(url: webpageURL, resolvingAgainstBaseURL: true)
        else {
            return false
        }
        
        // handle appflyer deeplinks
        // https://keyapp.onelink.me/rRAL/transfer?deep_link_value=<seed>
        if urlComponents.url?.absoluteString.hasPrefix("https://keyapp.onelink.me/rRAL/transfer") == true {
            // Delegate work to AppsFlyerLib
            AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
            return true
        }
        
        // handle natively
        else {
            handleCustomUniversalLinks(urlComponents: urlComponents)
            return true
        }
    }
    
    // MARK: - Helpers

    private func handleCustomUniversalLinks(urlComponents: URLComponents) {
        // Universal link must start with https
        guard urlComponents.scheme == "https" else {
            return
        }
        
        // Intercom survey
        // https://key.app/intercom?intercom_survey_id=133423424
        if urlComponents.host == "key.app",
           urlComponents.path == "/intercom",
           let queryItem = urlComponents.queryItems?.first(where: { $0.name == "intercom_survey_id" }),
           let value = queryItem.value
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                GlobalAppState.shared.surveyID = value
            }
        }
        
        // Send via link
        // https://t.key.app/<seed>
        else if urlComponents.host == "t.key.app" {
            GlobalAppState.shared.sendViaLinkUrl = urlComponents.url
        }
    }
    
    private func handleCustomURIScheme(urlComponents components: URLComponents) {
        let host = components.host
        let path = components.path
        let scheme = components.scheme
        
        // Login to test with urischeme
        // keyapptest://onboarding/seedPhrase?value=seed-phrase-separated-by-hyphens&pincode=222222
        if scheme == "keyapptest",
           Environment.current != .release,
           host == "onboarding",
           path == "/seedPhrase",
           let params = components.queryItems,
           let seedPhrase: String = params.first(where: { $0.name == "value" })?.value,
           let pincode: String = params.first(where: { $0.name == "pincode" })?.value
        {
            let userAccountManager: UserAccountManager = Resolver.resolve()
            let appEventHandler: AppEventHandlerType = Resolver.resolve()
            let pincodeStorageService: PincodeStorageType = Resolver.resolve()
            let authService: AuthenticationHandlerType = Resolver.resolve()
            Task {
                appEventHandler.delegate?.disablePincodeOnFirstAppear()
                pincodeStorageService.save(pincode)
                Defaults.isBiometryEnabled = false
                
                try await userAccountManager.add(seedPhrase: seedPhrase.components(separatedBy: "-"), derivablePath: .default, name: nil, deviceShare: nil, ethAddress: nil)
                
                try await Task.sleep(nanoseconds: 1_000_000_000)
                authService.authenticate(presentationStyle: nil)
            }
        }
        
        // Send via link
        // keyapp://t/<seed>
        else if scheme == "keyapp", host == "t" {
            let seed = String(path.dropFirst())
            GlobalAppState.shared.sendViaLinkUrl = urlFromSeed(seed)
        }
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
        
        // handle appflyer link
        if( deepLinkObj.isDeferred == true) {
            NSLog("[AFSDK] This is a deferred deep link")
        }
        else {
            NSLog("[AFSDK] This is a direct deep link")
        }
        
        // disable
        guard let urlStringOptional = deepLinkObj.clickEvent["link"] as? Optional<String>,
              let urlString = urlStringOptional,
              let urlComponents = URLComponents(string: urlString),
              let host = urlComponents.host,
              host == "keyapp.onelink.me"
        else {
            return
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

//private func externalURLSchemes() -> [String] {
//    guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [AnyObject],
//          let urlSchemes = (urlTypes as? [[String: AnyObject]])?
//            .compactMap({$0["CFBundleURLSchemes"] as? [String]})
//            .reduce([], +)
//    else { return [] }
//    print(urlSchemes)
//    return urlSchemes
//}
