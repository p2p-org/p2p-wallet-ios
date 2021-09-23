//
//  AppDelegate+Injection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import Foundation

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register {KeychainAccountStorage()}
        register {AnalyticsManager()}.implements(AnalyticsManagerType.self)
        register {Root.ViewModel()}.implements(CreateOrRestoreWalletHandler.self).implements(OnboardingHandler.self)
    }
}
