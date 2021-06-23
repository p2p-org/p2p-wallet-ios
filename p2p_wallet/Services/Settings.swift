//
//  Settings.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

extension UIUserInterfaceStyle: DefaultsSerializable {}

extension Fiat: DefaultsSerializable {}

extension SolanaSDK.APIEndPoint: DefaultsSerializable {}

extension DefaultsKeys {
    var didSetEnableBiometry: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var isBiometryEnabled: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var didSetEnableNotifications: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var apiEndPoint: DefaultsKey<SolanaSDK.APIEndPoint> {
        .init(
            #function,
            defaultValue: .definedEndpoints.first!
        )
    }
    var walletName: DefaultsKey<[String: String]> {.init(#function, defaultValue: [:])}
    var localizedLanguage: DefaultsKey<LocalizedLanguage> {.init(#function, defaultValue: LocalizedLanguage(code: String(Locale.preferredLanguages[0].prefix(2))))}
    var appearance: DefaultsKey<UIUserInterfaceStyle> {.init(#function, defaultValue: .unspecified)}
    var slippage: DefaultsKey<Double> {.init(#function, defaultValue: 0.005)}
    var fiat: DefaultsKey<Fiat> {.init(#function, defaultValue: .usd)}
    var hiddenWalletPubkey: DefaultsKey<[String]> {.init(#function, defaultValue: [])}
    var unhiddenWalletPubkey: DefaultsKey<[String]> {.init(#function, defaultValue: [])}
    var isTermAndConditionsAccepted: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var isIntroductionViewed: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var hideZeroBalances: DefaultsKey<Bool> {.init(#function, defaultValue: true)}
    var useFreeTransaction: DefaultsKey<Bool> {.init(#function, defaultValue: true)}
    var p2pFeePayerPubkeys: DefaultsKey<[String]> {.init(#function, defaultValue: [])}
}
