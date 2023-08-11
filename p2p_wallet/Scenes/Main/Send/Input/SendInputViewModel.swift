import AnalyticsManager
import Combine
import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeyAppUI
import OrcaSwapSwift
import Resolver
import Send
import SolanaSwift
import UIKit

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

    private let flow: SendFlow
    private var wasMaxWarningToastShown: Bool = false
    private let preChosenAmount: Double?
    private let allowSwitchingMainAmountType: Bool

    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager

    init(
        recipient: Recipient,
        preChosenWallet: SolanaAccount?,
        preChosenAmount: Double?,
        flow: SendFlow,
        allowSwitchingMainAmountType: Bool,
        sendViaLinkSeed: String?
    ) {
        self.flow = flow
        self.preChosenAmount = preChosenAmount
        self.allowSwitchingMainAmountType = allowSwitchingMainAmountType

        let repository = Resolver.resolve(SolanaAccountsService.self)
        let wallets = repository.getWallets()

        let pricesService = Resolver.resolve(PriceService.self)

        // Setup source token
        let tokenInWallet: SolanaAccount
        switch recipient.category {
        case let .solanaTokenAddress(_, token):
            tokenInWallet = wallets
                .first(where: { $0.token.mintAddress == token.mintAddress }) ??
                SolanaAccount(token: TokenMetadata.nativeSolana)
        default:
            if let preChosenWallet {
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
                tokenInWallet = sortedWallets.first ?? SolanaAccount(token: TokenMetadata.nativeSolana)
            }
        }
        sourceWallet = tokenInWallet

        let feeTokenInWallet = wallets
            .first(where: { $0.token.mintAddress == TokenMetadata.usdc.mintAddress }) ??
            SolanaAccount(token: TokenMetadata.usdc)

        var exchangeRate = [String: TokenPrice]()
        var tokens = Set<TokenMetadata>()
        wallets.forEach {
            exchangeRate[$0.token.symbol] = $0.price
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
            try await Resolver.resolve(OrcaSwapType.self).load()
            try await Resolver.resolve(RelayContextManager.self).update()
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
                guard let self else { return }
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
                    amount: value?.inToken ?? 0
                )
            })
            .store(in: &subscriptions)

        inputAmountViewModel.changeAmount
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .sinkAsync(receiveValue: { [weak self] value in
                guard let self else { return }
                switch value.type {
                case .token:
                    _ = await self.stateMachine.accept(action: .changeAmountInToken(value.amount.inToken))
                    self.logAmountChanged(
                        symbol: self.currentState.token.symbol,
                        amount: value.amount.inToken
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
                    self.logTokenChosen(symbol: value.token.symbol)
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
                guard let self else { return }
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
                guard let self else { return }
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
                guard let self else { return }
                let text: String
                if self.currentState.feeWallet?.mintAddress == self.sourceWallet.mintAddress, self.currentState
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
                guard let self else { return }
                self.isFeeLoading = true
                _ = await self.stateMachine.accept(action: .changeFeeToken(newFeeToken.token))
                self.isFeeLoading = false
            }
            .store(in: &subscriptions)

        $isSliderOn
            .sinkAsync(receiveValue: { [weak self] isSliderOn in
                guard let self else { return }
                if isSliderOn {
                    await self.send()
                    self.isSliderOn = false
                    self.showFinished = false
                }
            })
            .store(in: &subscriptions)

        changeTokenPressed
            .sink { [weak self] in
                guard let self else { return }
                self.logChooseTokenClick(
                    tokenName: self.currentState.token.symbol
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

        $sourceWallet.eraseToAnyPublisher()
            .sink { [weak self] currentWallet in
                guard let self else { return }
                if currentWallet.price == nil {
                    self.turnOffInputSwitch()
                } else if
                    currentWallet.isUsdcOrUsdt, currentWallet.price?.value == 1.0
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
        guard currentState.token.isNative else { return }
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
            logSendClickCreateLink(symbol: token.symbol, amount: amountInToken, pubkey: address)
        }

        await MainActor.run {
            let transaction = SendTransaction(
                isFakeSendTransaction: isFakeSendTransaction,
                isFakeSendTransactionError: isFakeSendTransactionError,
                isFakeSendTransactionNetworkError: isFakeSendTransactionNetworkError,
                isLinkCreationAvailable: stateMachine.currentState.feeRelayerContext?.usageStatus
                    .reachedLimitLinkCreation == false,
                recipient: recipient,
                sendViaLinkSeed: sendViaLinkSeed,
                amount: amountInToken,
                amountInFiat: amountInFiat,
                walletToken: sourceWallet,
                address: address,
                payingFeeWallet: feeWallet,
                feeAmount: currentState.feeInToken,
                currency: inputAmountViewModel.mainAmountType == .fiat ? Defaults.fiat.symbol : sourceWallet.token
                    .symbol,
                analyticEvent: .sendNewConfirmButtonClick(
                    sendFlow: flow.rawValue,
                    token: currentState.token.symbol,
                    max: inputAmountViewModel.wasMaxUsed,
                    amountToken: currentState.amountInToken,
                    amountUSD: currentState.amountInFiat,
                    fee: currentState.fee.total > 0,
                    fiatInput: inputAmountViewModel.mainAmountType == .fiat,
                    signature: "",
                    pubKey: nil
                )
            )
            self.transaction.send(transaction)
        }
    }
}

// MARK: - Analytics

private extension SendInputViewModel {
    func logOpen() {
        analyticsManager.log(event: .sendnewInputScreen(sendFlow: flow.rawValue))
    }

    func logEnjoyFeeTransaction() {
        analyticsManager.log(event: .sendnewFreeTransactionClick(sendFlow: flow.rawValue))
    }

    func logChooseTokenClick(tokenName: String) {
        analyticsManager.log(event: .sendnewTokenInputClick(
            tokenName: tokenName,
            sendFlow: flow.rawValue
        ))
    }

    func logTokenChosen(symbol: String) {
        analyticsManager.log(event: .sendClickChangeTokenChosen(
            tokenName: symbol,
            sendFlow: flow.rawValue
        ))
    }

    func logFiatInputClick(isCrypto: Bool) {
        analyticsManager.log(event: .sendnewFiatInputClick(crypto: isCrypto, source: flow.rawValue))
    }

    func logAmountChanged(symbol: String, amount: Double) {
        analyticsManager.log(event: .sendClickChangeTokenValue(
            tokenName: symbol,
            tokenValue: amount,
            sendFlow: flow.rawValue
        ))
    }

    func logSendClickCreateLink(symbol: String, amount: Double, pubkey: String) {
        analyticsManager.log(event: .sendClickCreateLink(
            sendFlow: flow.rawValue,
            tokenName: symbol,
            tokenValue: amount,
            pubkey: pubkey
        ))
    }
}

private extension SolanaAccount {
    var isSendable: Bool {
        lamports > 0 && !isNFTToken
    }

    var isUsdcOrUsdt: Bool {
        [TokenMetadata.usdc.mintAddress, TokenMetadata.usdt.mintAddress].contains(token.mintAddress)
    }
}
