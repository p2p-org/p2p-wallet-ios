//
//  AppDelegate+Injection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import Foundation
import SolanaSwift

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register {KeychainAccountStorage()}
            .implements(SolanaSDKAccountStorage.self)
            .implements(ICloudStorageType.self)
            .implements(NameStorageType.self)
            .scope(.application)
        register {AnalyticsManager()}
            .implements(AnalyticsManagerType.self)
            .scope(.application)
        register {CryptoComparePricesFetcher()}
            .implements(PricesFetcher.self)
            .scope(.application)
        register {NameService()}
            .implements(NameServiceType.self)
            .scope(.application)
        register { AddressFormatter() }
            .implements(AddressFormatterType.self)
            .scope(.application)
        
        // MARK: - Root
        register {Root.ViewModel()}
            .implements(RootViewModelType.self)
            .implements(ChangeNetworkResponder.self)
            .implements(ChangeLanguageResponder.self)
            .implements(CreateOrRestoreWalletHandler.self)
            .implements(OnboardingHandler.self)
            .scope(.shared)
        
        // MARK: - CreateOrRestoreWallet
        register {CreateOrRestoreWallet.ViewModel()}
            .implements(CreateOrRestoreWalletViewModelType.self)
            .scope(.shared)
        
        // CreateWallet
        register {CreateWallet.ViewModel()}
            .implements(CreateWalletViewModelType.self)
            .scope(.shared)
        
        // CreateSecurityKeys
        register {CreateSecurityKeys.ViewModel()}
            .implements(CreateSecurityKeysViewModelType.self)
            .scope(.shared)
        
        // RestoreWallet
        register {RestoreWallet.ViewModel()}
            .implements(RestoreWalletViewModelType.self)
            .implements(AccountRestorationHandler.self)
            .scope(.shared)
        
        // DerivableAccounts
        register { _, args in
            DerivableAccounts.ViewModel(phrases: args())
        }
            .implements(DerivableAccountsListViewModelType.self)
            .scope(.shared)
        
        // MARK: - Onboarding
        register {Onboarding.ViewModel()}
            .implements(OnboardingViewModelType.self)
            .scope(.shared)
        
        // MARK: - ResetPinCodeWithSeedPhrases
        register {ResetPinCodeWithSeedPhrases.ViewModel()}
            .implements(ResetPinCodeWithSeedPhrasesViewModelType.self)
            .scope(.shared)
        
        // MARK: - Main
        register {MainViewModel()}
            .implements(MainViewModelType.self)
            .implements(AuthenticationHandler.self)
            .scope(.shared)
    }
}
