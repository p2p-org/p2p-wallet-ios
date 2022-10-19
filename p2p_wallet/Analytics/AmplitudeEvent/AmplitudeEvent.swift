//
//  AmplitudeEvent.swift
//  p2p_wallet
//
//  Created by Ivan on 13.09.2022.
//

import AnalyticsManager
import Foundation

enum AmplitudeEvent: AnalyticsEvent {
    // MARK: - Onboarding

    /// Event 32: The user sees the splash screen
    case splashViewed

    /// Event 33: The user swipes the slider on the splash screen once
    case splashCreating

    /// Event 34: The user presses the "I already have a wallet" button
    case splashRestoring

    // MARK: - Create wallet

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

    /// Event 49: The wallet was successfully created
    case walletCreated(lastScreen: String)

    /// Event 50: The wallet was successfully created
    case walletRestored(lastScreen: String)

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

    // MARK: - Main

    case mainScreenWalletsOpen
    case mainScreenBuyOpen
    case mainScreenReceiveOpen
    case mainScreenSendOpen
    case mainScreenSwapOpen
    case mainScreenQrOpen
    case mainScreenSettingsOpen
    case mainScreenTokenDetailsOpen(tokenTicker: String)
    case mainCopyAddress

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

    // MARK: - Receive

    case receiveViewed(fromPage: String)
    case receiveNameCopy
    case receiveAddressCopied
    case receiveNameShare
    case receiveAddressShare
    case receiveWalletAddressCopy
    case receiveUsercardShared
    case receiveQRSaved
    case receiveViewingExplorer
    case receiveStartScreen
    case actionButtonReceive

    // MARK: - Send

    case sendStartScreen
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
    case sendRecipientScreen
    case sendReviewScreen
    case sendPaste
    case sendFillingAddress
    case sendApprovedScreen
    case sendConfirmButtonPressed(
        sendNetwork: String,
        sendCurrency: String,
        sendSum: String,
        sendMax: Bool,
        sendUsd: String,
        sendFree: Bool,
        sendUsername: Bool,
        sendAccountFeeToken: String
    )
    case actionButtonSend

    // MARK: - Swap

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
    case swapStartScreen
    case swapClickReviewButton
    case swapClickApproveButton
    case actionButtonSwap

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
    case signOut

    // choose token
    case tokenListViewed(lastScreen: String, tokenListLocation: String)
    case tokenListSearching(searchString: String)
    case tokenChosen(tokenName: String)

    // Buy
    case buyCurrencyChanged(
        fromCurrency: String,
        toCurrency: String
    )
    case buyCoinChanged(
        fromCoin: String,
        toCoin: String
    )
    case buyTotalShowed
    case buyChosenMethodPayment(type: String)
    case buyButtonPressed(
        sumCurrency: String,
        sumCoin: String,
        currency: String,
        coin: String,
        paymentMethod: String,
        bankTransfer: Bool,
        typeBankTransfer: String?
    )
    case buyStatusTransaction(success: Bool)
    case buyScreenOpened(lastScreen: String)
    case moonpayWindowClosed

    // General
    case appOpened(sourceOpen: AppOpenedContext)
    case actionButtonClick

    // Onboarding
    case onboardingStartButton
    case createConfirmPin(result: Bool)
    case restoreWalletButton
    case selectRestoreOption(restoreOption: String, keychaineOption: Bool)
    case restoreConfirmPin(result: Bool)
}

// MARK: - AppOpenedContext

extension AmplitudeEvent {
    enum AppOpenedContext: String {
        case direct
        case push
        case deeplink
    }
}
