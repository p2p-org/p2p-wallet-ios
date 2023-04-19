//
//  KeyAppAnalyticsEvent.swift
//  p2p_wallet
//
//  Created by Ivan on 13.09.2022.
//

import AnalyticsManager
import Foundation

enum KeyAppAnalyticsEvent: AnalyticsEvent {
    // MARK: - Onboarding

    /// Event 32: The user sees the splash screen
    case splashViewed

    /// Event 33: The user swipes the slider on the splash screen once
    case splashCreating

    /// Event 34: The user presses the "I already have a wallet" button
    case splashRestoring

    // MARK: - Create wallet

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
    case createPhoneClickButton
    case createSmsScreen
    case restorePhoneScreen
    case restorePhoneClickButton
    case restoreSmsScreen
    case restoreSmsValidation(result: Bool)

    /// Event 49: The wallet was successfully created
    case walletCreated(lastScreen: String)

    /// Event 50: The wallet was successfully created
    case walletRestored(lastScreen: String)

    // setup
    case setupPinKeydown1
    case setupPinKeydown2
    case setupOpen(fromPage: String)
    case setupFaceidOpen
    case bioApproved(lastScreen: String)
    case bioRejected
    case setupAllowPushOpen
    case pushApprove
    case setupFinishOpen
    case setupFinishClick
    case setupWelcomeBackOpen
    // recovery
    case recoveryOpen(fromPage: String)
    case restoreManualInvoked
    case restoreAppleInvoked
    case recoveryEnterSeedOpen
    case recoveryEnterSeedPaste
    case recoveryEnterSeedKeydown
    case recoveryDerivableAccountsPathSelected(path: String)
    case recoveryRestoreClick
    case recoveryDoneClick
    case recoveryDerivableAccountsOpen

    // MARK: - Main

    case mainScreenWalletsOpen(isSellEnabled: Bool)
    case mainScreenBuyOpen
    case mainCopyAddress
    case mainScreenSendOpen
    case mainScreenSwapOpen
    case mainScreenReceiveOpen
    case mainScreenTokenDetailsOpen(tokenTicker: String)
    case mainScreenBuyToken(tokenName: String)
    case mainSwap(isSellEnabled: Bool)

    // token_details
    case tokenDetailsOpen(tokenTicker: String)
    case tokenDetailQrClick
    case tokenDetailsBuyClick
    case tokenReceiveViewed
    case tokenDetailsSendClick
    case tokenDetailsSwapClick
    case tokenDetailsDetailsOpen
    case tokenDetailsAddressCopy
    case tokenDetailsActivityScroll(pageNum: Int)

    // MARK: - Receive

    case receiveViewed(fromPage: String)
    case receiveNameCopy
    case receiveAddressCopied
    case receiveNameShare
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
    case sendChangeInputMode(selectedValue: String) // Fiat (USD, EUR)
    case sendAmountKeydown(sum: Double)
    case sendAvailableClick(sum: Double)
    case sendAddressKeydown
    case sendQR_Scanning
    case sendSendClick(tokenTicker: String, sum: Double)
    case sendExplorerClick(txStatus: String)
    case sendRecipientScreen
    case sendReviewScreen
    case sendPaste
    case sendFillingAddress
    case sendApprovedScreen
    case actionButtonSend
    case sendNewConfirmButtonClick(
        source: String,
        token: String,
        max: Bool,
        amountToken: Double,
        amountUSD: Double,
        fee: Bool,
        fiatInput: Bool
    )
    case sendClickStartCreateLink
    case sendClickChangeTokenChosen(tokenName: String, sendFlow: String)
    case sendClickChangeTokenValue(tokenName: String, tokenValue: Double, sendFlow: String)
    case sendClickCreateLink(tokenName: String, tokenValue: Double, pubkey: String)
    case sendCreatingLinkEndScreenOpen(tokenName: String, tokenValue: Double, pubkey: String)
    case sendClickShareLink
    case sendClickCopyLink
    case sendClickDefaultError
    case sendCreatingLinkProcessScreenOpen

    // MARK: - Send new

    case sendnewRecipientScreen(source: String)
    case sendnewRecipientAdd(type: String, source: String)
    case sendnewBuyClickButton(source: String)
    case sendnewReceiveClickButton(source: String)
    case sendnewInputScreen(source: String)
    case sendnewTokenInputClick(tokenName: String, source: String, sendFlow: String)
    case sendnewFreeTransactionClick(source: String, sendFlow: String)
    case sendnewFiatInputClick(crypto: Bool, source: String)

    // MARK: - Swap

    case swapViewed(lastScreen: String)
    case swapChangingTokenA(tokenA_Name: String)
    case swapChangingTokenB(tokenB_Name: String)
    case swapTokenAAmountKeydown(sum: Double)
    case swapTokenBAmountKeydown(sum: Double)
    case swapAvailableClick(sum: Double)
    case swapReversing
    case swapShowingSettings
    case swapSlippageClick
    case swapPayNetworkFeeWithClick
    case swapSwapFeesClick
    case swapSlippageKeydown(slippage: Double)
    case swapTryAgainClick(error: String)
    case swapStartScreen
    case swapClickReviewButton
    case actionButtonSwap
    case swapExplorerClick(txStatus: String)

    // #131
    case swapUserConfirmed(
        tokenA_Name: String,
        tokenB_Name: String,
        swapSum: Double,
        swapMAX: Bool,
        swapUSD: Double,
        priceSlippage: Double,
        feesSource: String
    )

    // #132
    case swapStarted(
        tokenA_Name: String,
        tokenB_Name: String,
        swapSum: Double,
        swapMAX: Bool,
        swapUSD: Double,
        priceSlippage: Double,
        feesSource: String
    )

    // #133
    case swapApprovedByNetwork(
        tokenA_Name: String,
        tokenB_Name: String,
        swapSum: Double,
        swapMAX: Bool,
        swapUSD: Double,
        priceSlippage: Double,
        feesSource: String
    )

    // #134
    case swapCompleted(
        tokenA_Name: String,
        tokenB_Name: String,
        swapSum: Double,
        swapMAX: Bool,
        swapUSD: Double,
        priceSlippage: Double,
        feesSource: String
    )
    case swapClickApproveButton

    // MARK: - Jupiter swap
    case swapStartScreenNew(lastScreen: String, from: String, to: String)
    case swapChangingTokenAClick(tokenAName: String)
    case swapChangingTokenBClick(tokenBName: String)
    case swapChangingTokenA(tokenAName: String, tokenAValue: Double)
    case swapReturnFromChangingTokenA
    case swapChangingTokenB(tokenBName: String, tokenBValue: Double)
    case swapReturnFromChangingTokenB
    case swapChangingValueTokenA(tokenAName: String, tokenAValue: Double)
    case swapChangingValueTokenB(tokenBName: String, tokenBValue: Double)
    case swapChangingValueTokenAAll(tokenAName: String, tokenAValue: Double)
    case swapSwitchTokens(tokenAName: String, tokenBName: String)
    case swapPriceImpactLow(priceImpact: Decimal)
    case swapPriceImpactHigh(priceImpact: Decimal)
    case swapErrorTokenAInsufficientAmount
    case swapErrorTokenPairNotExist
    case swapClickApproveButtonNew(tokenA: String, tokenB: String, swapSum: Double, swapUSD: Double, signature: String)

    // Transaction detail
    case swapTransactionProgressScreen
    case swapTransactionProgressScreenDone
    case swapErrorDefault(isBlockchainRelated: Bool)
    case swapErrorSlippage
    // Swap settings

    case swapSettingsClick
    case swapSettingsFeeClick(feeName: String)
    case swapSettingsSlippage(slippageLevelPercent: Double)
    case swapSettingsSlippageCustom(slippageLevelPercent: Double)
    case swapSettingsSwappingThroughChoice(variant: String)
    // MARK: - Scan QR

    case scanQrSuccess
    case scanQrClose

    // MARK: - Settings

    case settingsHideBalancesClick(hide: Bool)
    case settingsСurrencySelected(сurrency: String)
    case settingsBackupOpen
    case settingsLanguageSelected(language: String)
    case settingsSecuritySelected(faceId: Bool)

    case networkChanging(networkName: String)
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
    case buyStatusTransaction(success: Bool)
    case buyScreenOpened(lastScreen: String)
    case moonpayWindowOpened
    case moonpayWindowClosed
    case buyButtonPressed(
        sumCurrency: String,
        sumCoin: String,
        currency: String,
        coin: String,
        paymentMethod: String,
        bankTransfer: Bool,
        typeBankTransfer: String?
    )
    case buyBlockedScreenOpen
    case buyBlockedRegionClick
    case regionBuyScreenOpen
    case regionBuySearchClick
    case regionBuyResultClick(country: String)
    case buyChangeCountryClick

    // General
    case appOpened(sourceOpen: String)
    case actionButtonClick(isSellEnabled: Bool)

    // Onboarding
    case restoreWalletButton
    case selectRestoreOption(restoreOption: String, keychaineOption: Bool)
    case restoreConfirmPin(result: Bool)
    case onboardingTorusRequest(
        methodName: String,
        minutes: Int,
        seconds: Int,
        milliseconds: Int,
        result: String
    )
    case onboardingStartButton
    case creationPhoneScreen
    case createSmsValidation(result: Bool)
    case createConfirmPin(result: Bool)
    case usernameCreationScreen
    case usernameCreationButton(result: Bool)
    case restoreSeed
    case onboardingMerged
    case login

    // RenBTC
    case renbtcCreation(result: String)
    
    // PhoneScreen
    case creationLoginScreen

    // Username
    case usernameSkipButton(result: Bool)

    case startDeleteAccount
    case confirmDeleteAccount

    // MARK: - Action

    case actionPanelSendToken(tokenName: String)
    case actionPanelSwapToken(tokenName: String)

    // MARK: - QR
    
    case QR_Share

    // MARK: - Seed

    case seedPhraseCopy

    // MARK: - Sell

    case sellClicked(source: String)
    case sellClickedServerError
    case sellClickedSorryMinAmount
    case sellFinishSend
    case sellOnlySOLNotification
    case sellAmount
    case sellAmountNext
    case sellMoonpayOpenNotification
    case sellMoonpay
    
    // MARK: - History
    case historyOpened(sentViaLink: Bool)
    case historySendClicked(status: String)
    case historyClickBlockSendViaLink
    case historySendClickTransaction
    case historySendClickCopyTransaction
    case historySendClickShareTransaction
    
    // MARK: - Claim
    
    case claimStartScreenOpen
    case claimClickConfirmed(pubkey: String, tokenName: String, tokenValue: Double)
    case claimClickHide
    case claimEndScreenOpen
    case claimClickEnd
    case claimErrorAlreadyClaimed
    case claimErrorDefaultReject
}
