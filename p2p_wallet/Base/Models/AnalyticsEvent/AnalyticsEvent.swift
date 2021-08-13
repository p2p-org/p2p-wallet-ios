//
//  AnalyticsEvent.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/06/2021.
//

import Foundation

enum AnalyticsEvent {
    // first_in
    case firstInOpen
    case firstInCreateWalletClick
    case firstInIHaveWalletClick
    // create_wallet
    case createWalletOpen
    case createWalletCopySeedClick
    case createWalletIHaveSavedWordsClick
    case createWalletBackupToIcloudClick
    case createWalletNextClick
    // setup
    case setupOpen(fromPage: String)
    case setupPinKeydown1
    case setupPinKeydown2
    case setupFaceidOpen
    case setupFaceidClick(faceID: Bool)
    case setupAllowPushOpen
    case setupAllowPushSelected(push: Bool)
    case setupFinishOpen
    case setupFinishClick
    case setupWelcomeBackOpen
    // recovery
    case recoveryOpen(fromPage: String)
    case recoveryRestoreManualyClick
    case recoveryRestoreIcloudClick
    case recoveryEnterSeedOpen
    case recoveryEnterSeedKeydown
    case recoveryEnterSeedPaste
    case recoveryDoneClick
    case recoveryDerivableAccountsOpen
    case recoveryDerivableAccountsPathSelected(path: String)
    case recoveryRestoreClick

    // main_screen
    case mainScreenWalletsOpen
    case mainScreenBuyOpen
    case mainScreenReceiveOpen
    case mainScreenSendOpen
    case mainScreenSwapOpen
    case mainScreenQrOpen
    case mainScreenSettingsOpen
    case mainScreenTokenDetailsOpen(tokenTicker: String)
    // token_details
    case tokenDetailsOpen(tokenTicker: String)
    case tokenDetailQrClick
    case tokenDetailsBuyClick
    case tokenDetailsReceiveClick
    case tokenDetailsSendClick
    case tokenDetailsSwapClick
    case tokenDetailsAddressCopy
    case tokenDetailsActivityScroll(pageNum: Int)
    case tokenDetailsDetailsOpen
    // receive
    case receiveOpen(fromPage: String)
    case receiveAddressCopy
    case receiveAddressShare
    case receiveViewExplorerOpen
    // send
    case sendOpen(fromPage: String)
    case sendSelectTokenClick(tokenTicker: String)
    case sendChangeInputMode(selectedValue: String) // Fiat (USD, EUR), Token
    case sendAmountKeydown(sum: Double)
    case sendAvailableClick(sum: Double)
    case sendAddressKeydown
    case sendScanQrClick
    case sendSendClick(tokenTicker: String, sum: Double)
    case sendDoneClick(txStatus: String)
    case sendExplorerClick(txStatus: String)
    case sendTryAgainClick(error: String)
    case sendCancelClick(error: String)
    // swap
    case swapOpen(fromPage: String)
    case swapTokenASelectClick(tokenTicker: String)
    case swapTokenBSelectClick(tokenTicker: String)
    case swapTokenAAmountKeydown(sum: Double)
    case swapTokenBAmountKeydown(sum: Double)
    case swapAvailableClick(sum: Double)
    case swapReverseClick
    case swapSettingsClick
    case swapSlippageClick
    case swapSlippageKeydown(slippage: Double)
    case swapSwapClick(tokenA: String, tokenB: String, sumA: Double, sumB: Double)
    case swapDoneClick(txStatus: String)
    case swapExplorerClick(txStatus: String)
    case swapTryAgainClick(error: String)
    case swapCancelClick(error: String)
    // scan_qr
    case scanQrOpen(fromPage: String)
    case scanQrSuccess
    case scanQrClose
    // settings
    case settingsOpen(fromPage: String)
    case settingsNetworkSelected(network: String)
    case settingsHideBalancesClick(hide: Bool)
    case settingBackupOpen
    case settingsSecuritySelected(faceId: Bool)
    case settingsLanguageSelected(language: String)
    case settingsAppearanceSelected(appearance: String)
    case settingsСurrencySelected(сurrency: String)
    case settingsLogoutClick
}
