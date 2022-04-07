//
//  AnalyticsEvent.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/06/2021.
//

import Foundation

enum AnalyticsEvent: MirrorableEnum {
    // first_in
    case firstInOpen
    case splashCreating
    case splashRestoring
    // create_wallet
    case createWalletOpen
    case createSeedInvoked
    case backingUpCopying
    case backingUpSaving
    case backingUpRenewing
    case usernameSkipped(usernameField: String)
    case usernameSaved(lastScreen: String)
    case usernameReserved
    case createWalletTermsAndConditionsClick
    case backingUpIcloud
    case backingUpManually
    case backingUpError
    // setup
    case setupOpen(fromPage: String)
    case setupPinKeydown1
    case setupPinKeydown2
    case setupFaceidOpen
    case bioApproved(lastScreen: String)
    case bioRejected
    case setupAllowPushOpen
    case pushRejected
    case pushApproved(lastScreen: String)
    case setupFinishOpen
    case setupFinishClick
    case setupWelcomeBackOpen
    // recovery
    case recoveryOpen(fromPage: String)
    case restoreManualInvoked
    case restoreAppleInvoked
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
    case tokenReceiveViewed
    case tokenDetailsSendClick
    case tokenDetailsSwapClick
    case tokenDetailsAddressCopy
    case tokenDetailsActivityScroll(pageNum: Int)
    case tokenDetailsDetailsOpen
    // receive
    case receiveViewed(fromPage: String)
    case receiveNameCopy
    case receiveAddressCopied
    case receiveNameShare
    case receiveQrcodeShare
    case receiveAddressShare
    case receiveWalletAddressCopy
    case receiveUsercardShared
    case receiveQRSaved
    case receiveViewingExplorer
    // send
    case sendViewed(lastScreen: String)
    case sendSelectTokenClick(tokenTicker: String)
    case sendChangeInputMode(selectedValue: String) // Fiat (USD, EUR), Token
    case sendAmountKeydown(sum: Double)
    case sendAvailableClick(sum: Double)
    case sendAddressKeydown
    case sendQrScanning
    case sendSendClick(tokenTicker: String, sum: Double)
    case sendMakeAnotherTransactionClick(txStatus: String)
    case sendExplorerClick(txStatus: String)
    case sendTryAgainClick(error: String)
    case sendCancelClick(error: String)
    // swap
    case swapViewed(lastScreen: String)
    case swapChangingTokenA(tokenAName: String)
    case swapChangingTokenB(tokenBName: String)
    case swapTokenAAmountKeydown(sum: Double)
    case swapTokenBAmountKeydown(sum: Double)
    case swapAvailableClick(sum: Double)
    case swapReversing
    case swapShowingSettings
    case swapSlippageClick
    case swapPayNetworkFeeWithClick
    case swapSwapFeesClick
    case swapSlippageKeydown(slippage: Double)
    case swapSwapClick(tokenA: String, tokenB: String, sumA: Double, sumB: Double)
    case swapMakeAnotherTransactionClick(txStatus: String)
    case swapExplorerClick(txStatus: String)
    case swapTryAgainClick(error: String)
    case swapCancelClick(error: String)

    // #131
    case swapUserConfirmed(
        tokenAName: String,
        tokenBName: String,
        swapSum: Double,
        swapMAX: Bool,
        swapUSD: Double,
        priceSlippage: Double,
        feesSource: String
    )

    // #132
    case swapStarted(
        tokenAName: String,
        tokenBName: String,
        swapSum: Double,
        swapMAX: Bool,
        swapUSD: Double,
        priceSlippage: Double,
        feesSource: String
    )

    // #133
    case swapApprovedByNetwork(
        tokenAName: String,
        tokenBName: String,
        swapSum: Double,
        swapMAX: Bool,
        swapUSD: Double,
        priceSlippage: Double,
        feesSource: String
    )

    // #134
    case swapCompleted(
        tokenAName: String,
        tokenBName: String,
        swapSum: Double,
        swapMAX: Bool,
        swapUSD: Double,
        priceSlippage: Double,
        feesSource: String
    )

    // scan_qr
    case scanQrOpen(fromPage: String)
    case scanQrSuccess
    case scanQrClose
    // settings
    case settingsOpen(lastScreen: String)
    case networkChanging(networkName: String)
    case settingsHideBalancesClick(hide: Bool)
    case settingsBackupOpen
    case settingsSecuritySelected(faceId: Bool)
    case settingsLanguageSelected(language: String)
    case settingsAppearanceSelected(appearance: String)
    case settingsСurrencySelected(сurrency: String)
    case signedOut
    case signOut(lastScreen: String)

    // choose token
    case tokenListViewed(lastScreen: String, tokenListLocation: String)
    case tokenListSearching(searchString: String)
    case tokenChosen(tokenName: String)
}

extension AnalyticsEvent {
    /// eventName is snakeCased of event minus params, for example: firstInOpen(scene: String) becomes first_in_open
    var eventName: String? {
        mirror.label.snakeCased()
    }

    var params: [AnyHashable: Any]? {
        mirror.params.isEmpty ? nil : mirror.params
    }
}

private extension String {
    func snakeCased() -> String? {
        let pattern = "([a-z0-9])([A-Z])"

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
            .uppercaseFirst
    }
}
