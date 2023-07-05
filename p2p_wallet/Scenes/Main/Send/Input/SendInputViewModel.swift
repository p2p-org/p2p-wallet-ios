// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AnalyticsManager
import Combine
import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeyAppUI
import Resolver
import Send
import SolanaPricesAPIs
import SolanaSwift

final class SendInputViewModel: BaseViewModel, ObservableObject {
    enum Status {
        case initializing
        case initializingFailed
        case ready
    }

    // MARK: - Sub view models

    let inputAmountViewModel: SendInputAmountViewModel

    @Published var status: Status = .initializing

    var lock: Bool {
        switch status {
        case .initializing: return true
        case .initializingFailed: return true
        case .ready: return false
        }
    }

    @Published var sourceWallet: SolanaAccount

    @Published var feeTitle = L10n.fees("")
    @Published var isFeeLoading: Bool = true
    @Published var loadingState: LoadableState = .loaded

    // ActionButton
    @Published var actionButtonData = SliderActionButtonData.zero
    @Published var isSliderOn = false
    @Published var showFinished = false

    let isTokenChoiceEnabled: Bool

    #if !RELEASE
        @Published var isFakeSendTransaction: Bool = Defaults.isFakeSendTransaction {
            didSet {
                Defaults.isFakeSendTransaction = isFakeSendTransaction
            }
        }

        @Published var isFakeSendTransactionError: Bool = Defaults.isFakeSendTransactionError {
            didSet {
                Defaults.isFakeSendTransactionError = isFakeSendTransactionError
                if isFakeSendTransactionError {
                    isFakeSendTransactionNetworkError = false
                }
            }
        }

        @Published var isFakeSendTransactionNetworkError: Bool = Defaults.isFakeSendTransactionNetworkError {
            didSet {
                Defaults.isFakeSendTransactionNetworkError = isFakeSendTransactionNetworkError
                if isFakeSendTransactionNetworkError {
                    isFakeSendTransactionError = false
                }
            }
        }
    #endif

    let changeTokenPressed = PassthroughSubject<Void, Never>()
    let feeInfoPressed = PassthroughSubject<Void, Never>()
    let openFeeInfo = PassthroughSubject<Bool, Never>()
    let changeFeeToken = PassthroughSubject<SolanaAccount, Never>()

    let snackbar = PassthroughSubject<SnackBar, Never>()
    let transaction = PassthroughSubject<SendTransaction, Never>()

    var currentState: SendInputState { stateMachine.currentState }

    let stateMachine: SendInputStateMachine

    // MARK: - Private

    private let source: SendSource
    private var wasMaxWarningToastShown: Bool = false
    private let preChosenAmount: Double?
    private let allowSwitchingMainAmountType: Bool

    // MARK: - Dependencies

    private let walletsRepository: SolanaAccountsService
    private let pricesService: PricesServiceType
    @Injected private var analyticsManager: AnalyticsManager

    init(
        recipient: Recipient,
        preChosenWallet: SolanaAccount?,
        preChosenAmount: Double?,
        source: SendSource,
        allowSwitchingMainAmountType: Bool,
        sendViaLinkSeed: String?
    ) {
        self.source = source
        self.preChosenAmount = preChosenAmount
        self.allowSwitchingMainAmountType = allowSwitchingMainAmountType

        let repository = Resolver.resolve(SolanaAccountsService.self)
        walletsRepository = repository
        let wallets = repository.getWallets()

        let pricesService = Resolver.resolve(PricesService.self)
        self.pricesService = pricesService

        // Setup source token
        let tokenInWallet: SolanaAccount
        switch recipient.category {
        case let .solanaTokenAddress(_, token):
            tokenInWallet = wallets
                .first(where: { $0.token.address == token.address }) ?? SolanaAccount(token: Token.nativeSolana)
        default:
            if let preChosenWallet = preChosenWallet {
                tokenInWallet = preChosenWallet
            } else {
                let preferOrder: [String: Int] = ["USDC": 1, "USDT": 2]
                let sortedWallets = wallets
                    .filter(\.isSendable)
                    .sorted { (lhs: SolanaAccount, rhs: SolanaAccount) -> Bool in
                        if preferOrder[lhs.token.symbol] != nil || preferOrder[rhs.token.symbol] != nil {
                            return (preferOrder[lhs.token.symbol] ?? 3) < (preferOrder[rhs.token.symbol] ?? 3)
                        } else {
                            return lhs.amountInCurrentFiat > rhs.amountInCurrentFiat
                        }
                    }
                tokenInWallet = sortedWallets.first ?? SolanaAccount(token: Token.nativeSolana)
            }
        }
        sourceWallet = tokenInWallet

        let feeTokenInWallet = wallets
            .first(where: { $0.token.address == Token.usdc.address }) ?? SolanaAccount(token: Token.usdc)

        var exchangeRate = [String: CurrentPrice]()
        var tokens = Set<Token>()
        wallets.forEach {
            exchangeRate[$0.token.symbol] = CurrentPrice(value: $0.price?.doubleValue)
            tokens.insert($0.token)
        }

        let env = UserWalletEnvironments(
            wallets: wallets,
            ethereumAccount: nil,
            exchangeRate: exchangeRate,
            tokens: tokens
        )

        let state = SendInputState.zero(
            recipient: recipient,
            token: tokenInWallet.token,
            feeToken: feeTokenInWallet.token,
            userWalletState: env,
            sendViaLinkSeed: sendViaLinkSeed
        )

        stateMachine = .init(
            initialState: state,
            services: .init(
                swapService: SwapServiceImpl(
                    feeRelayerCalculator: Resolver.resolve(RelayService.self).feeCalculator,
                    orcaSwap: Resolver.resolve()
                ),
                feeService: SendFeeCalculatorImpl(
                    feeRelayerCalculator: Resolver.resolve(RelayService.self).feeCalculator
                ),
                solanaAPIClient: Resolver.resolve()
            )
        )

        inputAmountViewModel = SendInputAmountViewModel(initialToken: tokenInWallet)

        let preChoosenWalletAvailable = preChosenWallet != nil
        let recipientIsDirectSPLTokenAddress = recipient.category.isDirectSPLTokenAddress
        let thereIsOnlyOneOrNoneWallets = wallets.filter(\.isSendable).count <= 1
        let shouldDisableChosingToken = preChoosenWalletAvailable || recipientIsDirectSPLTokenAddress ||
            thereIsOnlyOneOrNoneWallets
        isTokenChoiceEnabled = !shouldDisableChosingToken

        super.init()

        initialize()
        logOpen()
        bind()
    }

    func initialize() {
        Task { [weak self] in
            guard let self else { return }
            self.status = .initializing

            let nextState = await self.stateMachine
                .accept(action: .initialize(.init {
                    // get current context
                    let relayContextManager = Resolver.resolve(RelayContextManager.self)
                    return try await relayContextManager.getCurrentContextOrUpdate()
                }))

            // disable adding amount if amount is pre-chosen
            if let amount = self.preChosenAmount {
                Task { [weak self] in
                    guard let self else { return }
                    self.inputAmountViewModel.mainAmountType = .token
                    self.inputAmountViewModel.amountText = amount.toString()
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        self.inputAmountViewModel.isDisabled = true
                    }
                }
            }

            switch nextState.status {
            case .error(reason: .initializeFailed(_)):
                self.status = .initializingFailed
            default:
                self.status = .ready
            }
        }
    }

    func openKeyboard() {
        DispatchQueue.main.async {
            guard !self.inputAmountViewModel.isFirstResponder else { return }
            self.inputAmountViewModel.isFirstResponder = true
        }
    }

    @MainActor
    func load() async {
        loadingState = .loading
        do {
            try await Resolver.resolve(SwapServiceType.self).reload()
            loadingState = .loaded
        } catch {
            loadingState = .error(error.readableDescription)
        }
    }

    func getSendViaLinkURL() -> String? {
        guard let seed = currentState.sendViaLinkSeed else { return nil }
        return try? Resolver.resolve(SendViaLinkDataService.self)
            .restoreURL(givenSeed: seed)
            .absoluteString
    }
}

private extension SendInputViewModel {
    func bind() {
        stateMachine.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self else { return }
                switch value.status {
                case .error(reason: .networkConnectionError(_)):
                    self.handleConnectionError()
                default:
                    self.inputAmountViewModel.maxAmountToken = value.maxAmountInputInToken
                    self.updateFeeTitle()
                }
            }
            .store(in: &subscriptions)

        inputAmountViewModel.tokenAmountChanged
            .sink(receiveValue: { [weak self] value in
                guard let self, self.status != .initializing else { return }
                self.logAmountChanged(
                    symbol: self.currentState.token.symbol,
                    amount: value?.inToken ?? 0,
                    isSendingViaLink: self.currentState.isSendingViaLink
                )
            })
            .store(in: &subscriptions)

        inputAmountViewModel.changeAmount
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .sinkAsync(receiveValue: { [weak self] value in
                guard let self = self else { return }
                switch value.type {
                case .token:
                    _ = await self.stateMachine.accept(action: .changeAmountInToken(value.amount.inToken))
                    self.logAmountChanged(
                        symbol: self.currentState.token.symbol,
                        amount: value.amount.inToken,
                        isSendingViaLink: self.currentState.isSendingViaLink
                    )
                case .fiat:
                    _ = await self.stateMachine.accept(action: .changeAmountInFiat(value.amount.inFiat))
                }
                self.updateInputAmountView()
            })
            .store(in: &subscriptions)

        $sourceWallet
            .sinkAsync(receiveValue: { [weak self] value in
                guard let self else { return }
                await MainActor.run { [weak self] in self?.isFeeLoading = true }
                if self.status != .initializing {
                    self.logTokenChosen(
                        symbol: value.token.symbol,
                        isSendingViaLink: self.currentState.isSendingViaLink
                    )
                }
                _ = await self.stateMachine.accept(action: .changeUserToken(value.token))
                await MainActor.run { [weak self] in
                    self?.inputAmountViewModel.token = value
                    self?.isFeeLoading = false
                }
            })
            .store(in: &subscriptions)

        $isFeeLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.feeTitle = L10n.fees("")
                    self.actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.calculatingTheFees)
                } else {
                    self.updateInputAmountView()
                }
            }
            .store(in: &subscriptions)

        feeInfoPressed
            .sink { [weak self] in
                guard let self = self else { return }
                self.openFeeInfo.send(self.currentState.fee == .zero)
                if self.currentState.fee == .zero,
                   self.feeTitle.elementsEqual(L10n.enjoyFreeTransactions)
                {
                    self.logEnjoyFeeTransaction(isSendingViaLink: self.currentState.isSendingViaLink)
                }
            }
            .store(in: &subscriptions)

        inputAmountViewModel.maxAmountPressed
            .sink { [weak self] _ in
                guard let self = self else { return }
                let text: String
                if self.currentState.feeWallet?.mintAddress == self.sourceWallet.mintAddress && self.currentState
                    .fee != .zero
                {
                    text = L10n.calculatedBySubtractingTheAccountCreationFeeFromYourBalance
                } else {
                    text = L10n.usingTheMaximumAmount(self.sourceWallet.token.symbol)
                }
                self.handleSuccess(text: text)
                self.vibrate()
            }
            .store(in: &subscriptions)

        changeFeeToken
            .sinkAsync { [weak self] newFeeToken in
                guard let self = self else { return }
                self.isFeeLoading = true
                _ = await self.stateMachine.accept(action: .changeFeeToken(newFeeToken.token))
                self.isFeeLoading = false
            }
            .store(in: &subscriptions)

        $isSliderOn
            .sinkAsync(receiveValue: { [weak self] isSliderOn in
                guard let self = self else { return }
                if isSliderOn {
                    await self.send()
                    self.isSliderOn = false
                    self.showFinished = false
                }
            })
            .store(in: &subscriptions)

        changeTokenPressed
            .sink { [weak self] in
                guard let self = self else { return }
                self.logChooseTokenClick(
                    tokenName: self.currentState.token.symbol,
                    isSendingViaLink: self.currentState.isSendingViaLink
                )
            }
            .store(in: &subscriptions)

        inputAmountViewModel.$mainAmountType
            .dropFirst()
            .sink { [weak self] value in
                self?.logFiatInputClick(isCrypto: value == .token)
            }
            .store(in: &subscriptions)

        $status
            .sink { [weak self] value in
                guard value == .ready else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self?.openKeyboard() }
            }
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            pricesService.isPricesAvailablePublisher,
            $sourceWallet.eraseToAnyPublisher()
        )
        .sink { [weak self] isPriceAvailable, currentWallet in
            guard let self else { return }
            if !isPriceAvailable || currentWallet.price == nil {
                self.turnOffInputSwitch()
            } else if
                let amount = currentWallet.amount,
                currentWallet.isUsdcOrUsdt && abs(amount - currentWallet.amountInCurrentFiat) <= 0.021
            {
                self.turnOffInputSwitch()
            } else {
                self.inputAmountViewModel.isSwitchAvailable = self.allowSwitchingMainAmountType
            }
        }
        .store(in: &subscriptions)
    }
}

private extension SendInputViewModel {
    func turnOffInputSwitch() {
        inputAmountViewModel.mainAmountType = .token
        inputAmountViewModel.isSwitchAvailable = false
    }

    func updateInputAmountView() {
        guard currentState.amountInToken != .zero else {
            inputAmountViewModel.isError = false
            actionButtonData = SliderActionButtonData.zero
            return
        }
        switch currentState.status {
        case let .error(.inputTooHigh(maxAmount)):
            inputAmountViewModel.isError = true
            actionButtonData = SliderActionButtonData(
                isEnabled: false,
                title: L10n.max(maxAmount.tokenAmountFormattedString(
                    symbol: sourceWallet.token.symbol,
                    maximumFractionDigits: Int(sourceWallet.token.decimals),
                    roundingMode: .down
                ))
            )
            checkMaxButtonIfNeeded()
        case let .error(.inputTooLow(minAmount)):
            inputAmountViewModel.isError = true
            actionButtonData = SliderActionButtonData(
                isEnabled: false,
                title: L10n.min(minAmount.tokenAmountFormattedString(
                    symbol: sourceWallet.token.symbol,
                    maximumFractionDigits: Int(sourceWallet.token.decimals),
                    roundingMode: .down
                ))
            )
        case .error(reason: .insufficientAmountToCoverFee):
            inputAmountViewModel.isError = false
            actionButtonData = SliderActionButtonData(
                isEnabled: false,
                title: L10n.insufficientFundsToCoverFees
            )
        case .error(reason: .initializeFailed(_)):
            inputAmountViewModel.isError = false
            actionButtonData = SliderActionButtonData(
                isEnabled: true,
                title: L10n.tryAgain
            )
        case .error(reason: .insufficientFunds):
            inputAmountViewModel.isError = true
            actionButtonData = SliderActionButtonData(
                isEnabled: false,
                title: L10n.insufficientFunds
            )
            checkMaxButtonIfNeeded()
        default:
            wasMaxWarningToastShown = false
            inputAmountViewModel.isError = false
            if !currentState.isSendingViaLink {
                var title = L10n.send + " "
                title += currentState.amountInToken.tokenAmountFormattedString(
                    symbol: currentState.token.symbol,
                    maximumFractionDigits: Int(currentState.token.decimals),
                    roundingMode: .down
                )
                actionButtonData = SliderActionButtonData(isEnabled: true, title: title)
            } else {
                actionButtonData = SliderActionButtonData(
                    isEnabled: true,
                    title: L10n.createLink
                )
            }
        }
    }

    func checkMaxButtonIfNeeded() {
        guard currentState.token.isNativeSOL else { return }
        let range = currentState.maxAmountInputInSOLWithLeftAmount ..< currentState.maxAmountInputInToken
        if range.contains(currentState.amountInToken) {
            if !wasMaxWarningToastShown {
                handleSuccess(text: L10n.weLeftAMinimumSOLBalanceToSaveTheAccountAddress)
                wasMaxWarningToastShown = true
            }
            inputAmountViewModel.isMaxButtonVisible = true
        }
    }

    func vibrate() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func updateFeeTitle() {
        // if send via link, just return enjoyFreeTransactions
        if currentState.isSendingViaLink {
            feeTitle = L10n.fees(0)
        }

        // otherwise show fees in conditions
        else if currentState.fee == .zero, currentState.amountInToken == 0, currentState.amountInFiat == 0 {
            feeTitle = L10n.enjoyFreeTransactions
        } else if currentState.fee == .zero {
            feeTitle = L10n.fees(0)
        } else {
            let symbol = currentState.fee == .zero ? "" : currentState.tokenFee.symbol
            feeTitle = L10n
                .fees(
                    currentState.feeInToken.total.convertToBalance(decimals: Int(currentState.tokenFee.decimals))
                        .tokenAmountFormattedString(symbol: symbol, roundingMode: .down)
                )
        }
    }

    func handleConnectionError() {
        handleError(text: L10n.youHaveNoInternetConnection)
    }

    func handleInitializingError() {
        handleError(text: L10n.initializingError)
    }

    func handleUnknownError() {
        handleError(text: L10n.somethingWentWrong)
    }

    func handleError(text: String) {
        snackbar.send(SnackBar(title: "🥺", text: text, buttonTitle: L10n.hide, buttonAction: { SnackBar.hide() }))
    }

    func handleSuccess(text: String) {
        snackbar.send(SnackBar(title: "✅", text: text))
    }

    func send() async {
        guard let sourceWallet = currentState.sourceWallet
        else { return }

        let address: String
        let amountInToken = currentState.amountInToken
        let recipient = currentState.recipient
        let feeWallet = currentState.feeWallet

        switch recipient.category {
        case let .solanaTokenAddress(walletAddress, _):
            address = walletAddress.base58EncodedString
        default:
            address = currentState.recipient.address
        }
        logConfirmButtonClick()

        await MainActor.run {
            showFinished = true
        }

        try? await Task.sleep(nanoseconds: 500_000_000)

        let isSendingViaLink = stateMachine.currentState.isSendingViaLink

        #if !RELEASE
            let isFakeSendTransaction = isFakeSendTransaction
            let isFakeSendTransactionError = isFakeSendTransactionError
            let isFakeSendTransactionNetworkError = isFakeSendTransactionNetworkError
        #else
            let isFakeSendTransaction = false
            let isFakeSendTransactionError = false
            let isFakeSendTransactionNetworkError = false
        #endif
        let sendViaLinkSeed = stateMachine.currentState.sendViaLinkSeed
        let token = currentState.token
        let amountInFiat = currentState.amountInFiat

        if isSendingViaLink {
            logSendClickCreateLink(symbol: token.symbol, amount: amountInToken, pubkey: sourceWallet.pubkey ?? "")
        }

        await MainActor.run {
            let transaction = SendTransaction(
                isFakeSendTransaction: isFakeSendTransaction,
                isFakeSendTransactionError: isFakeSendTransactionError,
                isFakeSendTransactionNetworkError: isFakeSendTransactionNetworkError,
                recipient: recipient,
                sendViaLinkSeed: sendViaLinkSeed,
                amount: amountInToken,
                amountInFiat: amountInFiat,
                walletToken: sourceWallet,
                address: address,
                payingFeeWallet: feeWallet,
                feeAmount: currentState.feeInToken,
                currency: inputAmountViewModel.mainAmountType == .fiat ? Defaults.fiat.symbol : sourceWallet.token
                    .symbol
            )
            self.transaction.send(transaction)
        }
    }
}

// MARK: - Analytics

private extension SendInputViewModel {
    func logOpen() {
        analyticsManager.log(event: .sendnewInputScreen(source: source.rawValue))
    }

    func logEnjoyFeeTransaction(isSendingViaLink: Bool) {
        analyticsManager.log(event: .sendnewFreeTransactionClick(
            source: source.rawValue,
            sendFlow: isSendingViaLink ? "Send_Via_Link" : "Send"
        ))
    }

    func logChooseTokenClick(tokenName: String, isSendingViaLink: Bool) {
        analyticsManager.log(event: .sendnewTokenInputClick(
            tokenName: tokenName,
            source: source.rawValue,
            sendFlow: isSendingViaLink ? "Send_Via_Link" : "Send"
        ))
    }

    func logTokenChosen(symbol: String, isSendingViaLink: Bool) {
        analyticsManager.log(event: .sendClickChangeTokenChosen(
            tokenName: symbol,
            sendFlow: isSendingViaLink ? "Send_Via_Link" : "Send"
        ))
    }

    func logFiatInputClick(isCrypto: Bool) {
        analyticsManager.log(event: .sendnewFiatInputClick(crypto: isCrypto, source: source.rawValue))
    }

    func logAmountChanged(symbol: String, amount: Double, isSendingViaLink: Bool) {
        analyticsManager.log(event: .sendClickChangeTokenValue(
            tokenName: symbol,
            tokenValue: amount,
            sendFlow: isSendingViaLink ? "Send_Via_Link" : "Send"
        ))
    }

    func logSendClickCreateLink(symbol: String, amount: Double, pubkey: String) {
        analyticsManager.log(event: .sendClickCreateLink(tokenName: symbol, tokenValue: amount, pubkey: pubkey))
    }

    func logConfirmButtonClick() {
        analyticsManager.log(event: .sendNewConfirmButtonClick(
            source: source.rawValue,
            token: currentState.token.symbol,
            max: inputAmountViewModel.wasMaxUsed,
            amountToken: currentState.amountInToken,
            amountUSD: currentState.amountInFiat,
            fee: currentState.fee.total > 0,
            fiatInput: inputAmountViewModel.mainAmountType == .fiat
        ))
    }
}

private extension SolanaAccount {
    var isSendable: Bool {
        lamports ?? 0 > 0 && !isNFTToken
    }

    var isUsdcOrUsdt: Bool {
        [Token.usdc.address, Token.usdt.address].contains(token.address)
    }
}
