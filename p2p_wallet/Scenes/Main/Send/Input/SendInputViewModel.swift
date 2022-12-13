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

    let actionButtonViewModel: SendInputActionButtonViewModel
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

    // MARK: - Dependencies

    private let walletsRepository: WalletsRepository
    private let pricesService: PricesServiceType
    @Injected private var analyticsManager: AnalyticsManager

    init(recipient: Recipient, preChosenWallet: Wallet?, source: SendSource) {
        self.source = source
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
                    .filter({ $0.lamports ?? 0 > 0 })
                    .sorted { (lhs: Wallet, rhs: Wallet) -> Bool in
                        if preferOrder[lhs.token.symbol] != nil || preferOrder[rhs.token.symbol] != nil {
                            return (preferOrder[lhs.token.symbol] ?? 3) < (preferOrder[rhs.token.symbol] ?? 3)
                        } else {
                            return lhs.lamports ?? 0 < rhs.lamports ?? 0
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
            exchangeRate[$0.token.symbol] = pricesService.currentPrice(for: $0.token.symbol)
            tokens.insert($0.token)
        }

        let env = UserWalletEnvironments(wallets: wallets, exchangeRate: exchangeRate, tokens: tokens)

        let state = SendInputState.zero(
            recipient: recipient,
            token: tokenInWallet.token,
            feeToken: feeTokenInWallet.token,
            userWalletState: env
        )

        stateMachine = .init(
            initialState: state,
            services: .init(
                swapService: SwapServiceImpl(
                    feeRelayerCalculator: Resolver.resolve(FeeRelayer.self).feeCalculator, orcaSwap: Resolver.resolve()
                ),
                feeService: SendFeeCalculatorImpl(
                    feeRelayerCalculator: Resolver.resolve(FeeRelayer.self).feeCalculator
                ),
                solanaAPIClient: Resolver.resolve()
            )
        )

        inputAmountViewModel = SendInputAmountViewModel(initialToken: tokenInWallet)
        actionButtonViewModel = SendInputActionButtonViewModel()

        tokenViewModel = SendInputTokenViewModel(initialToken: tokenInWallet)

        let preChoosenWalletAvailable = preChosenWallet != nil
        let recipientIsDirectSPLTokenAddress = recipient.category.isDirectSPLTokenAddress
        let thereIsOnlyOneOrNoneWallets = wallets.filter { ($0.lamports ?? 0) > 0 }.count <= 1
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
                    try await Resolver.resolve(SwapServiceType.self).load()

                    let feeRelayerContextManager = Resolver.resolve(FeeRelayerContextManager.self)
                    try await feeRelayerContextManager.update()
                    return try await feeRelayerContextManager.getCurrentContext()
                }))

            switch nextState.status {
            case .error(reason: .initializeFailed(_)):
                self?.status = .initializingFailed
            default:
                self?.status = .ready
            }
        }
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
                    _ = await self.stateMachine.accept(action: .changeAmountInToken(value.amount))
                case .fiat:
                    _ = await self.stateMachine.accept(action: .changeAmountInFiat(value.amount))
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
                    self.actionButtonViewModel.actionButton = .init(isEnabled: false, title: L10n.calculatingTheFees)
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

        actionButtonViewModel.$isSliderOn
            .sinkAsync(receiveValue: { [weak self] isSliderOn in
                guard let self = self else { return }
                if isSliderOn {
                    await self.send()
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
    }
}

private extension SendInputViewModel {
    func updateInputAmountView() {
        guard currentState.amountInToken != .zero else {
            inputAmountViewModel.isError = false
            actionButtonViewModel.actionButton = .zero
            return
        }
        switch currentState.status {
        case let .error(.inputTooHigh(maxAmount)):
            inputAmountViewModel.isError = true
            actionButtonViewModel.actionButton = .init(
                isEnabled: false,
                title: L10n.max(maxAmount.tokenAmount(symbol: sourceWallet.token.symbol, roundingMode: .down))
            )
            if currentState.token.isNativeSOL && currentState.amountInToken != currentState.maxAmountInputInToken {
                if !wasMaxWarningToastShown {
                    handleSuccess(text: L10n.weLeftAMinimumSOLBalanceToSaveTheAccountAddress)
                    wasMaxWarningToastShown = true
                }
                inputAmountViewModel.isMaxButtonVisible = true
            }
        case let .error(.inputTooLow(minAmount)):
            inputAmountViewModel.isError = true
            actionButtonViewModel.actionButton = .init(
                isEnabled: false,
                title: L10n.min(minAmount.tokenAmount(symbol: sourceWallet.token.symbol, roundingMode: .down))
            )
        case .error(reason: .insufficientAmountToCoverFee):
            inputAmountViewModel.isError = false
            actionButtonViewModel.actionButton = .init(
                isEnabled: false,
                title: L10n.insufficientFundsToCoverFees
            )
        case .error(reason: .initializeFailed(_)):
            inputAmountViewModel.isError = false
            actionButtonViewModel.actionButton = .init(
                isEnabled: true,
                title: L10n.tryAgain
            )
        case .error(reason: .insufficientFunds):
            inputAmountViewModel.isError = false
            actionButtonViewModel.actionButton = .init(
                isEnabled: false,
                title: L10n.insufficientFunds
            )

        default:
            wasMaxWarningToastShown = false
            inputAmountViewModel.isError = false
            actionButtonViewModel.actionButton = .init(
                isEnabled: true,
                title: "\(L10n.send) \(currentState.amountInToken.tokenAmount(symbol: currentState.token.symbol, maximumFractionDigits: Int(currentState.token.decimals), roundingMode: .down))"
            )
        }
    }

    func vibrate() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func updateFeeTitle() {
        if currentState.fee == .zero, currentState.amountInToken == 0, currentState.amountInFiat == 0 {
            feeTitle = L10n.enjoyFreeTransactions
        } else if currentState.fee == .zero {
            feeTitle = L10n.fees(0)
        } else {
            let symbol = currentState.fee == .zero ? "" : currentState.tokenFee.symbol
            feeTitle = L10n
                .fees(
                    currentState.feeInToken.total.convertToBalance(decimals: Int(currentState.tokenFee.decimals))
                        .tokenAmount(symbol: symbol, roundingMode: .down)
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

        do {
            await MainActor.run {
                self.actionButtonViewModel.showFinished = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let transaction = SendTransaction(state: self.currentState) {
                        try? await Resolver.resolve(SendHistoryService.self).insert(recipient)

                        let trx = try await Resolver.resolve(SendActionService.self).send(
                            from: sourceWallet,
                            receiver: address,
                            amount: amountInToken,
                            feeWallet: feeWallet
                        )

                        return trx
                    }
                    self.transaction.send(transaction)
                }
            }
        } catch {
            if let error = error as? NSError,
               error.code == NSURLErrorNetworkConnectionLost || error.code == NSURLErrorNotConnectedToInternet
            {
                await MainActor.run { handleConnectionError() }
            } else {
                await MainActor.run { handleUnknownError() }
            }
        }
    }
}

// MARK: - Analytics

private extension SendInputViewModel {
    func logOpen() {
        analyticsManager.log(event: AmplitudeEvent.sendnewInputScreen(source: source.rawValue))
    }

    func logEnjoyFeeTransaction() {
        analyticsManager.log(event: AmplitudeEvent.sendnewFreeTransactionClick(source: source.rawValue))
    }

    func logChooseTokenClick() {
        analyticsManager.log(event: AmplitudeEvent.sendnewTokenInputClick(source: source.rawValue))
    }

    func logFiatInputClick(isCrypto: Bool) {
        analyticsManager.log(event: AmplitudeEvent.sendnewFiatInputClick(crypto: isCrypto, source: source.rawValue))
    }

    func logConfirmButtonClick() {
        analyticsManager.log(event: AmplitudeEvent.sendnewConfirmButtonClick(
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
