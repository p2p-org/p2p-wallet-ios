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
    // MARK: - Sub view models

    let actionButtonViewModel: SendInputActionButtonViewModel
    let inputAmountViewModel: SendInputAmountViewModel
    let tokenViewModel: SendInputTokenViewModel

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

    // MARK: - Dependencies

    private let walletsRepository: WalletsRepository
    private let pricesService: PricesServiceType
    private let sendAction: SendActionService
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
                tokenInWallet = preChosenWallet ?? wallets
                    .first(where: { $0.token.address == Token.nativeSolana.address }) ??
                    Wallet(token: Token.nativeSolana)
            } else {
                var preferOrder: [String: Int] = ["USDC": 1, "USDT": 2, "SOL": 3]
                let sortedWallets = wallets.sorted { (lhs: Wallet, rhs: Wallet) -> Bool in
                    if lhs.lamports == 0 { return false }
                    if rhs.lamports == 0 { return true }

                    return (preferOrder[lhs.token.symbol] ?? 4) < (preferOrder[rhs.token.symbol] ?? 4)
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

        let accountStorage = Resolver.resolve(AccountStorageType.self)
        sendAction = SendActionServiceImpl(
            contextManager: Resolver.resolve(),
            solanaAPIClient: Resolver.resolve(),
            blockchainClient: Resolver.resolve(),
            feeRelayer: Resolver.resolve(),
            account: accountStorage.account
        )

        inputAmountViewModel = SendInputAmountViewModel(initialToken: tokenInWallet)
        actionButtonViewModel = SendInputActionButtonViewModel()

        tokenViewModel = SendInputTokenViewModel(initialToken: tokenInWallet)

        let preChoosenWalletAvailable = preChosenWallet != nil
        let recipientIsDirectSPLTokenAddress = recipient.category.isDirectSPLTokenAddress
        let thereIsOnlyOneOrNoneWallets = wallets.filter {($0.lamports ?? 0) > 0}.count <= 1
        let shouldDisableChosingToken = preChoosenWalletAvailable || recipientIsDirectSPLTokenAddress ||
            thereIsOnlyOneOrNoneWallets
        tokenViewModel.isTokenChoiceEnabled = !shouldDisableChosingToken

        super.init()

        Task {
            await stateMachine
                .accept(action: .initialize(.init {
                    let feeRelayerContextManager = Resolver.resolve(FeeRelayerContextManager.self)
                    try await feeRelayerContextManager.update()
                    return try await feeRelayerContextManager.getCurrentContext()
                }))
        }

        logOpen()
        bind()
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
                case .error(reason: .initializeFailed(_)):
                    self.handleInitializingError()
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
                if self.currentState.feeWallet?.mintAddress == self.sourceWallet.mintAddress {
                    text = L10n.calculatedBySubtractingTheAccountCreationFeeFromYourBalance
                } else {
                    text = L10n.usingTheMaximumAmount(self.sourceWallet.token.symbol)
                }
                self.snackbar.send(SnackBar(title: "✅", text: text))
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
        case .error(.inputTooHigh):
            inputAmountViewModel.isError = true
            actionButtonViewModel.actionButton = .init(
                isEnabled: false,
                title: L10n.max(currentState.maxAmountInputInToken.tokenAmount(symbol: sourceWallet.token.symbol))
            )
        case let .error(.inputTooLow(minAmount)):
            inputAmountViewModel.isError = true
            actionButtonViewModel.actionButton = .init(
                isEnabled: false,
                title: L10n.min(minAmount.tokenAmount(symbol: sourceWallet.token.symbol))
            )
        case .error(reason: .insufficientAmountToCoverFee):
            inputAmountViewModel.isError = false
            actionButtonViewModel.actionButton = .init(
                isEnabled: false,
                title: L10n.insufficientFundsToCoverFees
            )

        default:
            inputAmountViewModel.isError = false
            actionButtonViewModel.actionButton = .init(
                isEnabled: true,
                title: "\(L10n.send) \(currentState.amountInToken.tokenAmount(symbol: currentState.token.symbol))"
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
                        .tokenAmount(symbol: symbol)
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

    func send() async {
        guard
            let sourceWallet = currentState.sourceWallet,
            let feeWallet = currentState.feeWallet
        else { return }

        let address: String
        switch currentState.recipient.category {
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
                        try await self.sendAction.send(
                            from: sourceWallet,
                            receiver: address,
                            amount: self.currentState.amountInToken,
                            feeWallet: feeWallet
                        )
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
