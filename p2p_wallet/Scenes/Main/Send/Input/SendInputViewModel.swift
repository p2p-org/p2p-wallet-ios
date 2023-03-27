// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AnalyticsManager
import Combine
import FeeRelayerSwift
import Foundation
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
    let tokenViewModel: SendInputTokenViewModel

    @Published var status: Status = .initializing

    var lock: Bool {
        switch status {
        case .initializing: return true
        case .initializingFailed: return true
        case .ready: return false
        }
    }

    @Published var sourceWallet: Wallet

    @Published var feeTitle = L10n.fees("")
    @Published var isFeeLoading: Bool = true
    
    @Published var loadingState: LoadableState = .loaded

    // ActionButton
    @Published var actionButtonData = SliderActionButtonData.zero
    @Published var isSliderOn = false
    @Published var showFinished = false
    
    #if !RELEASE
    @Published var isFakeSendTransaction: Bool = Defaults.isFakeSendTransaction {
        didSet {
            Defaults.isFakeSendTransaction = isFakeSendTransaction
        }
    }
    @Published var isFakeSendTransactionError: Bool = Defaults.isFakeSendTransactionError {
        didSet {
            Defaults.isFakeSendTransactionError = isFakeSendTransactionError
        }
    }
    #endif

    let feeInfoPressed = PassthroughSubject<Void, Never>()
    let openFeeInfo = PassthroughSubject<Bool, Never>()
    let changeFeeToken = PassthroughSubject<Wallet, Never>()

    let snackbar = PassthroughSubject<SnackBar, Never>()
    let transaction = PassthroughSubject<SendTransaction, Never>()

    var currentState: SendInputState { stateMachine.currentState }

    let stateMachine: SendInputStateMachine

    // MARK: - Private

    private let source: SendSource
    private var wasMaxWarningToastShown: Bool = false
    private let preChosenAmount: Double?

    // MARK: - Dependencies

    private let walletsRepository: WalletsRepository
    private let pricesService: PricesServiceType
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var sendViaLinkStorage: SendViaLinkStorage

    init(
        recipient: Recipient,
        preChosenWallet: Wallet?,
        preChosenAmount: Double?,
        source: SendSource,
        allowSwitchingMainAmountType: Bool,
        sendViaLinkSeed: String?
    ) {
        self.source = source
        self.preChosenAmount = preChosenAmount
        let repository = Resolver.resolve(WalletsRepository.self)
        walletsRepository = repository
        let wallets = repository.getWallets()

        let pricesService = Resolver.resolve(PricesService.self)
        self.pricesService = pricesService

        // Setup source token
        let tokenInWallet: Wallet
        switch recipient.category {
        case let .solanaTokenAddress(_, token):
            tokenInWallet = wallets
                .first(where: { $0.token.address == token.address }) ?? Wallet(token: Token.nativeSolana)
        default:
            if let preChosenWallet = preChosenWallet {
                tokenInWallet = preChosenWallet
            } else {
                let preferOrder: [String: Int] = ["USDC": 1, "USDT": 2]
                let sortedWallets = wallets
                    .filter(\.isSendable)
                    .sorted { (lhs: Wallet, rhs: Wallet) -> Bool in
                        if preferOrder[lhs.token.symbol] != nil || preferOrder[rhs.token.symbol] != nil {
                            return (preferOrder[lhs.token.symbol] ?? 3) < (preferOrder[rhs.token.symbol] ?? 3)
                        } else {
                            return lhs.amountInCurrentFiat > rhs.amountInCurrentFiat
                        }
                    }
                tokenInWallet = sortedWallets.first ?? Wallet(token: Token.nativeSolana)
            }
        }
        sourceWallet = tokenInWallet

        let feeTokenInWallet = wallets
            .first(where: { $0.token.address == Token.usdc.address }) ?? Wallet(token: Token.usdc)

        var exchangeRate = [String: CurrentPrice]()
        var tokens = Set<Token>()
        wallets.forEach {
            exchangeRate[$0.token.symbol] = pricesService.currentPrice(mint: $0.token.address)
            tokens.insert($0.token)
        }

        let env = UserWalletEnvironments(wallets: wallets, exchangeRate: exchangeRate, tokens: tokens)

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
                    feeRelayerCalculator: Resolver.resolve(RelayService.self).feeCalculator, orcaSwap: Resolver.resolve()
                ),
                feeService: SendFeeCalculatorImpl(
                    feeRelayerCalculator: Resolver.resolve(RelayService.self).feeCalculator
                ),
                solanaAPIClient: Resolver.resolve()
            )
        )

        inputAmountViewModel = SendInputAmountViewModel(initialToken: tokenInWallet, allowSwitchingMainAmountType: allowSwitchingMainAmountType)

        tokenViewModel = SendInputTokenViewModel(initialToken: tokenInWallet)

        let preChoosenWalletAvailable = preChosenWallet != nil
        let recipientIsDirectSPLTokenAddress = recipient.category.isDirectSPLTokenAddress
        let thereIsOnlyOneOrNoneWallets = wallets.filter(\.isSendable).count <= 1
        let shouldDisableChosingToken = preChoosenWalletAvailable || recipientIsDirectSPLTokenAddress ||
            thereIsOnlyOneOrNoneWallets
        tokenViewModel.isTokenChoiceEnabled = !shouldDisableChosingToken

        super.init()

        initialize()
        logOpen()
        bind()
    }

    func initialize() {
        Task { [weak self] in
            self?.status = .initializing

            let nextState = await stateMachine
                .accept(action: .initialize(.init {
                    // get current context
                    let relayContextManager = Resolver.resolve(RelayContextManager.self)
                    return try await relayContextManager.getCurrentContextOrUpdate()
                }))
            
            // disable adding amount if amount is pre-chosen
            if let amount = preChosenAmount {
                Task {
                    inputAmountViewModel.mainAmountType = .token
                    inputAmountViewModel.amountText = amount.toString()
                    await MainActor.run {
                        inputAmountViewModel.isDisabled = true
                    }
                }
            }

            switch nextState.status {
            case .error(reason: .initializeFailed(_)):
                self?.status = .initializingFailed
            default:
                self?.status = .ready
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
        return Resolver.resolve(SendViaLinkDataService.self).createURL(givenSeed: seed)?
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

        inputAmountViewModel.changeAmount
            .sinkAsync(receiveValue: { [weak self] value in
                guard let self = self else { return }
                switch value.type {
                case .token:
                    _ = await self.stateMachine.accept(action: .changeAmountInToken(value.amount.inToken))
                case .fiat:
                    _ = await self.stateMachine.accept(action: .changeAmountInFiat(value.amount.inFiat))
                }
                self.updateInputAmountView()
            })
            .store(in: &subscriptions)

        $sourceWallet
            .sinkAsync(receiveValue: { [weak self] value in
                await MainActor.run { [weak self] in self?.isFeeLoading = true }
                _ = await self?.stateMachine.accept(action: .changeUserToken(value.token))
                await MainActor.run { [weak self] in
                    self?.inputAmountViewModel.token = value
                    self?.tokenViewModel.token = value
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
                    self.logEnjoyFeeTransaction()
                }
            }
            .store(in: &subscriptions)

        inputAmountViewModel.maxAmountPressed
            .sink { [weak self] _ in
                guard let self = self else { return }
                let text: String
                if self.currentState.feeWallet?.mintAddress == self.sourceWallet.mintAddress && self.currentState.fee != .zero {
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

        tokenViewModel.changeTokenPressed
            .sink { [weak self] in self?.logChooseTokenClick() }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { self?.openKeyboard() })
            }
            .store(in: &subscriptions)
    }
}

private extension SendInputViewModel {
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
                title: L10n.max(maxAmount.tokenAmountFormattedString(symbol: sourceWallet.token.symbol, roundingMode: .down))
            )
            checkMaxButtonIfNeeded()
        case let .error(.inputTooLow(minAmount)):
            inputAmountViewModel.isError = true
            actionButtonData = SliderActionButtonData(
                isEnabled: false,
                title: L10n.min(minAmount.tokenAmountFormattedString(symbol: sourceWallet.token.symbol, roundingMode: .down))
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
            if currentState.isSendingViaLink {
                actionButtonData = SliderActionButtonData(
                    isEnabled: true,
                    title: "\(L10n.send) \(currentState.amountInToken.tokenAmountFormattedString(symbol: currentState.token.symbol, maximumFractionDigits: Int(currentState.token.decimals), roundingMode: .down))"
                )
            } else {
                actionButtonData = SliderActionButtonData(
                    isEnabled: true,
                    title: L10n.createAOneTimeLink
                )
            }
        }
    }

    func checkMaxButtonIfNeeded() {
        guard currentState.token.isNativeSOL else { return }
        let range = currentState.maxAmountInputInSOLWithLeftAmount..<currentState.maxAmountInputInToken
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
            feeTitle = L10n.enjoyFreeTransactions
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
        guard
            let sourceWallet = currentState.sourceWallet,
            let feeWallet = currentState.feeWallet
        else { return }

        let address: String
        let amountInToken = currentState.amountInToken
        let recipient = currentState.recipient

        switch recipient.category {
        case let .solanaTokenAddress(walletAddress, _):
            address = walletAddress.base58EncodedString
        default:
            address = currentState.recipient.address
        }
        logConfirmButtonClick()

        await MainActor.run {
            self.showFinished = true
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let isSendingViaLink = stateMachine.currentState.isSendingViaLink
        
        await MainActor.run {
            let transaction = SendTransaction(state: self.currentState) {
                // save recipient except send via link
                if !self.currentState.isSendingViaLink {
                    try? await Resolver.resolve(SendHistoryService.self).insert(recipient)
                }
                
                // Fake transaction for testing
                #if !RELEASE
                if self.isFakeSendTransaction {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    if self.isFakeSendTransactionError {
                        throw SolanaError.unknown
                    }
                    // save to storage
                    if self.currentState.isSendingViaLink {
                        self.saveSendViaLinkTransaction()
                    }
                    
                    return .fakeTransactionSignature(id: UUID().uuidString)
                }
                #endif
                
                // Real transaction
                let trx = try await Resolver.resolve(SendActionService.self).send(
                    from: sourceWallet,
                    receiver: address,
                    amount: amountInToken,
                    feeWallet: feeWallet,
                    ignoreTopUp: isSendingViaLink,
                    memo: isSendingViaLink ? .secretConfig("SEND_VIA_LINK_MEMO_PREFIX")!: nil,
                    operationType: isSendingViaLink ? .sendViaLink: .transfer
                )
                
                // save to storage
                if self.currentState.isSendingViaLink {
                    self.saveSendViaLinkTransaction()
                }

                return trx
            }
            self.transaction.send(transaction)
        }
    }
    
    // MARK: - Helpers

    func saveSendViaLinkTransaction() {
        guard let seed = currentState.sendViaLinkSeed else { return }
        let token = currentState.token
        sendViaLinkStorage.save(
            transaction: .init(
                amount: currentState.amountInToken,
                amountInFiat: currentState.amountInFiat,
                token: token,
                seed: seed,
                timestamp: Date()
            )
        )
    }
}

// MARK: - Analytics

private extension SendInputViewModel {
    func logOpen() {
        analyticsManager.log(event: .sendnewInputScreen(source: source.rawValue))
    }

    func logEnjoyFeeTransaction() {
        analyticsManager.log(event: .sendnewFreeTransactionClick(source: source.rawValue))
    }

    func logChooseTokenClick() {
        analyticsManager.log(event: .sendnewTokenInputClick(source: source.rawValue))
    }

    func logFiatInputClick(isCrypto: Bool) {
        analyticsManager.log(event: .sendnewFiatInputClick(crypto: isCrypto, source: source.rawValue))
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

private extension Wallet {
    var isSendable: Bool {
        lamports ?? 0 > 0 && !isNFTToken
    }
}
