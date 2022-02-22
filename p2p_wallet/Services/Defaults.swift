//
//  Defaults.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftyUserDefaults
import RenVMSwift

extension UIUserInterfaceStyle: DefaultsSerializable {}

extension Fiat: DefaultsSerializable {}

extension SolanaSDK.APIEndPoint: DefaultsSerializable {}

extension PayingToken: DefaultsSerializable {}

extension RenVM.Session: DefaultsSerializable {}

extension RenVM.LockAndMint.ProcessingTx: DefaultsSerializable {}

extension RenVM.BurnAndRelease.BurnDetails: DefaultsSerializable {}

extension DefaultsKeys {
    // Keychain-keys
    var keychainPincodeKey: DefaultsKey<String?> {.init(#function, defaultValue: nil)}
    var keychainPhrasesKey: DefaultsKey<String?> {.init(#function, defaultValue: nil)}
    var keychainDerivableTypeKey: DefaultsKey<String?> {.init(#function, defaultValue: nil)}
    var keychainWalletIndexKey: DefaultsKey<String?> {.init(#function, defaultValue: nil)}
    var keychainNameKey: DefaultsKey<String?> {.init(#function, defaultValue: nil)}
    
    var didSetEnableBiometry: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var isBiometryEnabled: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var didSetEnableNotifications: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var apiEndPoint: DefaultsKey<SolanaSDK.APIEndPoint> {
        .init(
            #function,
            defaultValue: .definedEndpoints.first!
        )
    }
    var didBackupOffline: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var walletName: DefaultsKey<[String: String]> {.init(#function, defaultValue: [:])}
    var localizedLanguage: DefaultsKey<LocalizedLanguage> {.init(#function, defaultValue: LocalizedLanguage(code: String(Locale.preferredLanguages[0].prefix(2))))}
    var appearance: DefaultsKey<UIUserInterfaceStyle> {.init(#function, defaultValue: .unspecified)}
    var slippage: DefaultsKey<Double> {.init(#function, defaultValue: 0.01)}
    var fiat: DefaultsKey<Fiat> {.init(#function, defaultValue: .usd)}
    var hiddenWalletPubkey: DefaultsKey<[String]> {.init(#function, defaultValue: [])}
    var unhiddenWalletPubkey: DefaultsKey<[String]> {.init(#function, defaultValue: [])}
    var hideZeroBalances: DefaultsKey<Bool> {.init(#function, defaultValue: true)}
    var useFreeTransaction: DefaultsKey<Bool> {.init(#function, defaultValue: true)}
    var p2pFeePayerPubkeys: DefaultsKey<[String]> {.init(#function, defaultValue: [])}
    var prices: DefaultsKey<Data> {.init(#function, defaultValue: Data())}
    var payingToken: DefaultsKey<PayingToken> {.init(#function, defaultValue: .splToken)}
    var renVMSession: DefaultsKey<RenVM.Session?> {.init(#function, defaultValue: nil)}
    var renVMProcessingTxs: DefaultsKey<[RenVM.LockAndMint.ProcessingTx]> {.init(#function, defaultValue: [])}
    var renVMSubmitedBurnTxDetails: DefaultsKey<[RenVM.BurnAndRelease.BurnDetails]> {.init(#function, defaultValue: [])}
    var forceCloseNameServiceBanner: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var authenticationBlockingTime: DefaultsKey<Date?> {.init(#function, defaultValue: nil)}
    var shouldShowConfirmAlertOnSend: DefaultsKey<Bool> {.init(#function, defaultValue: true)}
    var shouldShowConfirmAlertOnSwap: DefaultsKey<Bool> {.init(#function, defaultValue: true)}
}
