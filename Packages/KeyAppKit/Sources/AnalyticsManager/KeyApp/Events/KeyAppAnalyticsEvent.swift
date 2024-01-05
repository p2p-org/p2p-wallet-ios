import Foundation

public enum KeyAppAnalyticsEvent: AnalyticsEvent {
    // MARK: - Create wallet

    case createPhoneClickButton
    case createSmsScreen
    case restorePhoneScreen
    case restorePhoneClickButton
    case restoreSmsScreen
    case restoreSmsValidation(result: Bool)

    // setup
    case setupOpen(fromPage: String)
    case recoveryDerivableAccountsPathSelected(path: String)
    case recoveryRestoreClick
    case recoveryDerivableAccountsOpen

    // MARK: - Tabbar

    case mainSwap
    case mainWallet
    case mainHistory
    case mainSettings

    // MARK: - Main

    // Actions bar
    case mainScreenBuyBar
    case mainScreenReceiveBar
    case mainScreenSendBar
    case mainScreenSwapBar
    case mainScreenCashOutBar

    case mainScreenOpened(isSellEnabled: Bool)
    case mainScreenAddressClick
    case mainScreenAmountClick
    case mainScreenAddMoneyClick
    case mainScreenWithdrawClick
    case mainScreenMainClick
    case mainScreenTokenDetailsOpen(tokenTicker: String)
    case mainScreenBuyToken(tokenName: String)
    case mainScreenHiddenTokens

    case mainScreenCryptoClick
    case mainScreenSendClick
    case mainScreenHistoryClick
    case mainScreenSettingsClick

    case userAggregateBalanceBase(amountUsd: Double, currency: String)
    case userHasPositiveBalanceBase(state: Bool)

    // MARK: - Crypto

    case cryptoScreenOpened
    case cryptoAmountClick
    case cryptoReceiveClick
    case cryptoSwapClick
    case cryptoTokenClick(tokenName: String)
    case cryptoClaimTransferredViewed(claimCount: Int)
    case cryptoClaimTransferredClick

    case userAggregateBalanceTokens(amountUsd: Double, currency: String)
    case userHasPositiveBalanceTokens(state: Bool)

    // MARK: - Tokens

    // Action panel
    case tokenScreenBuyBar
    case tokenScreenReceiveBar
    case tokenScreenSendBar
    case tokenScreenSwapBar

    // tap on transaction on a token screen
    case tokenScreenTransaction(transactionId: String)

    // MARK: - Receive

    case receiveViewed(fromPage: String)
    case receiveQRSaved
    case receiveStartScreen
    case receiveTokenClick(tokenName: String)
    case receiveNetworkScreenOpen
    case receiveNetworkClickButton(network: String)
    case receiveCopyAddressClickButton(network: String)
    case receiveCopyLongAddressClick(network: String)
    case receiveCopyAddressUsername
    case actionButtonReceive
    case actionButtonBuy

    // MARK: - Send

    case sendViewed(lastScreen: String)
    case actionButtonSend
    case sendNewConfirmButtonClick(
        sendFlow: String,
        token: String,
        max: Bool,
        amountToken: Double,
        amountUSD: Double,
        fee: Bool,
        fiatInput: Bool,
        signature: String,
        pubKey: String?
    )
    // Bridges
    case sendBridgesScreenOpen
    case sendClickChangeTokenChosen(sendFlow: String)
    case sendClickChangeTokenValue(sendFlow: String)
    case sendClickStartCreateLink
    case sendClickChangeTokenChosen(tokenName: String, sendFlow: String)
    case sendClickChangeTokenValue(tokenName: String, tokenValue: Double, sendFlow: String)
    case sendClickCreateLink(sendFlow: String, tokenName: String, tokenValue: Double, pubkey: String)
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
    case sendnewInputScreen(sendFlow: String)
    case sendnewTokenInputClick(tokenName: String, sendFlow: String)
    case sendnewFreeTransactionClick(sendFlow: String)
    case sendnewFiatInputClick(crypto: Bool, source: String)

    // MARK: - Swap

    case swapViewed(lastScreen: String)
    case actionButtonSwap
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
    case swapChangingValueTokenB(tokenBName: String, tokenBValue: Double, transactionSimulation: Bool)
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
    case settingsSecuritySelected(faceId: Bool)
    case settingsSupportClick
    case settingsRecoveryClick
    case settingsPinClick
    case settingsFaceidClick
    case settingsLogOut

    case networkChanging(networkName: String)
    case signedOut

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
    case onboardingStartButton
    case creationPhoneScreen
    case createSmsValidation(result: Bool)
    case createConfirmPin(result: Bool)
    case createConfirmPinScreenOpened
    case createConfirmPinFirstClick
    case restoreConfirmPinScreenOpened
    case restoreConfirmPinFirstClick
    case usernameCreationScreen
    case usernameCreationButton(result: Bool)
    case restoreSeed
    case onboardingMerged
    case login

    // PhoneScreen
    case creationLoginScreen

    // Username
    case usernameSkipButton(result: Bool)

    case startDeleteAccount
    case confirmDeleteAccount

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

    // MARK: - Claim

    case claimAvailable(claim: Bool)
    case claimBridgesScreenOpen(from: String) // main, push
    case claimBridgesFeeClick
    case claimBridgesClickConfirmed(tokenName: String, tokenValue: Double, valueFiat: Double, free: Bool)
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

    // MARK: - Transaction

    case transactionBlockchainLinkClick

    // MARK: - Client Error

    case clientFrontendError(errorValue: String, errorFragment: String)
    case clientBackendError(errorValue: String, errorFragment: String)
}
