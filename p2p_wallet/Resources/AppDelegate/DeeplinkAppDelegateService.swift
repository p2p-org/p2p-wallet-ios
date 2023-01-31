//
//  DeeplinkAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import Resolver

final class DeeplinkAppDelegateService: NSObject, AppDelegateService {
    @Injected var authService: AuthenticationHandlerType
    @Injected var pincodeService: PincodeService

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard
            let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let host = components.host,
            let path = components.path,
            let params = components.queryItems
        else {
            return false
        }

        if Environment.current != .release, host == "security", path == "/pincode", let pincode: String = params.first(where: { $0.name == "value" })?.value {
            do {
                if try pincodeService.validatePincode(pincode) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.authService.authenticate(presentationStyle: nil)
                    }
                } else {
                    return false
                }
            } catch {
                return false
            }
        }

        return false
    }
}
