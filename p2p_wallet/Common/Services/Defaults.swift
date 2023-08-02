import CountriesAPI
import FirebaseRemoteConfig
import Foundation
import Onboarding
import SolanaSwift
import SwiftyUserDefaults
import UIKit

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
    var lastDeviceToken: DefaultsKey<Data?> { .init(#function, defaultValue: nil) }
    var apiEndPoint: DefaultsKey<APIEndPoint> {
        .init(
            #function,
            defaultValue: .definedEndpoints.first!
        )
    }

    var forcedFeeRelayerEndpoint: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var forcedNameServiceEndpoint: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var forcedNewSwapEndpoint: DefaultsKey<String?> { .init(#function, defaultValue: nil) }
    var forcedStrigaEndpoint: DefaultsKey<String?> { .init(#function, defaultValue: nil) }

    var didBackupOffline: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    var walletName: DefaultsKey<[String: String]> { .init(#function, defaultValue: [:]) }
    var localizedLanguage: DefaultsKey<LocalizedLanguage> {
        .init(#function, defaultValue: LocalizedLanguage(code: String(Locale.preferredLanguages[0].prefix(2))))
    }

    var appearance: DefaultsKey<UIUserInterfaceStyle> { .init(#function, defaultValue: .unspecified) }
    var fiat: DefaultsKey<Fiat> { .init(#function, defaultValue: .usd) }
    var hiddenWalletPubkey: DefaultsKey<[String]> { .init(#function, defaultValue: []) }
    var unhiddenWalletPubkey: DefaultsKey<[String]> { .init(#function, defaultValue: []) }
    var hideZeroBalances: DefaultsKey<Bool> { .init(#function, defaultValue: true) }

    var forceCloseNameServiceBanner: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    var shouldShowConfirmAlertOnSend: DefaultsKey<Bool> { .init(#function, defaultValue: true) }
    var shouldShowConfirmAlertOnSwap: DefaultsKey<Bool> { .init(#function, defaultValue: true) }

    var onboardingLastState: DefaultsKey<CreateWalletFlowState?> { .init(#function, defaultValue: nil) }

    var buyMinPrices: DefaultsKey<[String: [String: Double]]> {
        .init(#function, defaultValue: [:])
    }

    // Send
    var isTokenInputTypeChosen: DefaultsKey<Bool> { .init(#function, defaultValue: false) }

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

    var swapRouteRefeshRate: DefaultsKey<Double?> {
        .init(
            #function,
            defaultValue: RemoteConfig.remoteConfig().swapRouteRefresh
        )
    }

    #if !RELEASE
        var isFakeSendTransaction: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
        var isFakeSendTransactionError: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
        var isFakeSendTransactionNetworkError: DefaultsKey<Bool> { .init(#function, defaultValue: false) }
    #endif

    var isSellInfoPresented: DefaultsKey<Bool> { .init(#function, defaultValue: false) }

    var moonpayEnvironment: DefaultsKey<DefaultsKeys.MoonpayEnvironment> {
        DefaultsKey(#function, defaultValue: .production)
    }

    var moonpayInfoShouldHide: DefaultsKey<Bool> {
        .init(#function, defaultValue: false)
    }

    // Jupiter Swap
    var fromTokenAddress: DefaultsKey<String?> {
        .init(#function, defaultValue: nil)
    }

    var toTokenAddress: DefaultsKey<String?> {
        .init(#function, defaultValue: nil)
    }

    var ethBannerShouldHide: DefaultsKey<Bool> {
        .init(#function, defaultValue: false)
    }

    var strigaOTPResendCounter: DefaultsKey<ResendCounter?> {
        .init(#function, defaultValue: nil)
    }

    var strigaOTPConfirmErrorDate: DefaultsKey<Date?> {
        .init(#function, defaultValue: nil)
    }

    var strigaOTPResendErrorDate: DefaultsKey<Date?> {
        .init(#function, defaultValue: nil)
    }

    var bankTransferLastCountry: DefaultsKey<Country?> {
        .init(#function, defaultValue: nil)
    }

    var homeBannerVisibility: DefaultsKey<HomeBannerVisibility?> {
        .init(#function, defaultValue: nil)
    }
}

// MARK: - Moonpay Environment

extension DefaultsKeys {
    enum MoonpayEnvironment: String, DefaultsSerializable {
        case production
        case sandbox
    }
}
