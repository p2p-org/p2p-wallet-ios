//
//  Defaults.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import FirebaseRemoteConfig
import Foundation
import Onboarding
import RenVMSwift
import SolanaSwift
import SwiftyUserDefaults

extension UIUserInterfaceStyle: DefaultsSerializable {}

extension Fiat: DefaultsSerializable {}

extension APIEndPoint: DefaultsSerializable {}

extension CreateWalletFlowState: DefaultsSerializable {}

extension DefaultsKeys {
    // Device token
    var apnsDeviceToken: DefaultsKey<Data?> { .init(#function, defaultValue: nil) }
    
    // Keychain-keys
    var keychainPincodeKey: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var pincodeAttemptsKey: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var keychainPhrasesKey: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var keychainDerivableTypeKey: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var keychainWalletIndexKey: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var keychainNameKey: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var keychainEthAddressKey: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var keychainWalletMetadata: DefaultsKey<String?> { .init(#function, defaultValue: nil) }

    var didSetEnableBiometry: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    var isBiometryEnabled: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    var didSetEnableNotifications: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    var wasFirstAttemptForSendingToken: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    var lastDeviceToken: DefaultsKey<Data?> { .init(#function, defaultValue: nil) }
    var apiEndPoint: DefaultsKey<APIEndPoint> {
        .init(
            #function,
            defaultValue: .definedEndpoints.first!
        )
    }
    var forcedFeeRelayerEndpoint: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var forcedNameServiceEndpoint: DefaultsKey<String?> { .init(#function, defaultValue: nil) }

    var isCoingeckoProviderDisabled: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    var didBackupOffline: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    var walletName: DefaultsKey<[String: String]> { .init(#function, defaultValue: [:]) }
    var localizedLanguage: DefaultsKey<LocalizedLanguage> {
        .init(#function, defaultValue: LocalizedLanguage(code: String(Locale.preferredLanguages[0].prefix(2))))
    }

    var appearance: DefaultsKey<UIUserInterfaceStyle> { .init(#function, defaultValue: .unspecified) }
    var slippage: DefaultsKey<Double> { .init(#function, defaultValue: 0.01) }
    var fiat: DefaultsKey<Fiat> { .init(#function, defaultValue: .usd) }
    var hiddenWalletPubkey: DefaultsKey<[String]> { .init(#function, defaultValue: []) }
    var unhiddenWalletPubkey: DefaultsKey<[String]> { .init(#function, defaultValue: []) }
    var hideZeroBalances: DefaultsKey<Bool> { .init(#function, defaultValue: true) }
    var p2pFeePayerPubkeys: DefaultsKey<[String]> { .init(#function, defaultValue: []) }
    var prices: DefaultsKey<Data> { .init(#function, defaultValue: Data()) }
    var payingTokenMint: DefaultsKey<String> {
        .init(#function, defaultValue: PublicKey.wrappedSOLMint.base58EncodedString)
    }

    var forceCloseNameServiceBanner: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    var authenticationBlockingTime: DefaultsKey<Date?> { .init(#function, defaultValue: nil) }
    var shouldShowConfirmAlertOnSend: DefaultsKey<Bool> { .init(#function, defaultValue: true) }
    var shouldShowConfirmAlertOnSwap: DefaultsKey<Bool> { .init(#function, defaultValue: true) }

    var onboardingLastState: DefaultsKey<CreateWalletFlowState?> { .init(#function, defaultValue: nil) }

    // Sepa Buy
    var buyLastPaymentMethod: DefaultsKey<PaymentType> {
        .init(#function, defaultValue: PaymentType.bank)
    }

    var buyMinPrices: DefaultsKey<[String: [String: Double]]> {
        .init(#function, defaultValue: [:])
    }

    // Solend
    var isSolendTutorialShown: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    var isEarnBannerClosed: DefaultsKey<Bool> { .init(#function, defaultValue: false) }

    var solanaNegativeStatusFrequency: DefaultsKey<String?> {
        .init(
            #function,
            defaultValue: RemoteConfig.remoteConfig().solanaNegativeStatusFrequency
        )
    }

    var solanaNegativeStatusPercent: DefaultsKey<Int?> {
        .init(
            #function,
            defaultValue: RemoteConfig.remoteConfig().solanaNegativeStatusPercent
        )
    }

    var solanaNegativeStatusTimeFrequency: DefaultsKey<Int?> {
        .init(
            #function,
            defaultValue: RemoteConfig.remoteConfig().solanaNegativeStatusTimeFrequency
        )
    }
}
