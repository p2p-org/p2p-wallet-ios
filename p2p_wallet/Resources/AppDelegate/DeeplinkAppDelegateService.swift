//
//  DeeplinkAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import Resolver

final class DeeplinkAppDelegateService: NSObject, AppDelegateService {
    @Injected var userWalletManager: UserWalletManager
    @Injected var appEventHandler: AppEventHandlerType
    @Injected var pincodeStorageService: PincodeStorageType
    @Injected var authService: AuthenticationHandlerType

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard
            let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let host = components.host,
            let path = components.path,
            let params = components.queryItems
        else {
            return false
        }

        if
            Environment.current != .release,
            host == "onboarding",
            path == "/seedPhrase",
            let seedPhrase: String = params.first(where: { $0.name == "value" })?.value,
            let pincode: String = params.first(where: { $0.name == "pincode" })?.value
        {
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
}
