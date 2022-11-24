// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver
import Send
import SolanaPricesAPIs
import SolanaSwift

class SendInputViewModel: ObservableObject {

    // MARK: - Dependencies
    private let walletsRepository: WalletsRepository
    private let pricesService: PricesServiceType

    // MARK: - Variables
    private var subscriptions = Set<AnyCancellable>()

    private let stateMachine: SendInputStateMachine

    @Published private var state: SendInputState

    @Published var feeTitle = L10n.enjoyFreeTransactions
    let feeInfoPressed = PassthroughSubject<Void, Never>()

    // MARK: - Sub view models
    let actionButtonViewModel: SendInputActionButtonViewModel
    let inputAmountViewModel: SendInputAmountViewModel
    let tokenViewModel: SendInputTokenViewModel

    @Published var currentToken: Wallet
    @Published var openPickToken = false

    init(recipient: Recipient) {
        let repository = Resolver.resolve(WalletsRepository.self)
        self.walletsRepository = repository

        let pricesService = Resolver.resolve(PricesService.self)
        self.pricesService = pricesService

        let wallets = repository.getWallets()
        let tokenInWallet = wallets.first(where: { $0.token.address == Token.nativeSolana.address })
        self.currentToken = tokenInWallet!

        var exchangeRate = [String: CurrentPrice]()
        wallets.forEach { exchangeRate[$0.id] = pricesService.currentPrice(for: $0.id) }

        let state = SendInputState(
            status: .ready,
            recipient: recipient,
            token: .nativeSolana,
            tokenFee: .nativeSolana,
            userWalletEnvironments: .init(wallets: wallets, exchangeRate: exchangeRate),
            amountInFiat: .zero,
            amountInToken: .zero,
            fee: .zero,
            feeInToken: .zero
        )
        stateMachine = .init(initialState: state, services: .init(swapService: MockedSwapService(result: nil)))
        self.state = state

        self.inputAmountViewModel = SendInputAmountViewModel()
        self.actionButtonViewModel = SendInputActionButtonViewModel()
        self.tokenViewModel = SendInputTokenViewModel()

        tokenViewModel.isTokenChoiceEnabled = wallets.count > 1

        bind()
    }
}

private extension SendInputViewModel {
    func bind() {
        stateMachine.statePublisher
            .sink { [weak self] in self?.state = $0 }
            .store(in: &subscriptions)
        
        $state
            .sink { value in
                
            }
            .store(in: &subscriptions)

        inputAmountViewModel.switchPressed
            .sink { [weak self] in
                debugPrint("switchPressed")
            }
            .store(in: &subscriptions)

        tokenViewModel.changeTokenPressed
            .sink { [weak self] in
                self?.openPickToken = true
            }
            .store(in: &subscriptions)

        inputAmountViewModel.$amount
            .sinkAsync(receiveValue: { [weak self] value in
                guard let self = self else { return }
                let returnState = await self.stateMachine.accept(action: .changeAmountInToken(value))
                await MainActor.run {
                    switch returnState.status {
                    case .error(.inputTooHigh):
                        self.inputAmountViewModel.isError = true
                        self.actionButtonViewModel.actionButton = .init(isEnabled: false, title: L10n.max(self.inputAmountViewModel.maxAmount.tokenAmount(symbol: self.currentToken.token.symbol)))
                    case .error(.inputTooLow):
                        self.inputAmountViewModel.isError = true
                        self.actionButtonViewModel.actionButton = .init(isEnabled: false, title: L10n.min(0.0.tokenAmount(symbol: self.currentToken.token.symbol)))
                    default:
                        self.inputAmountViewModel.isError = false
                        self.actionButtonViewModel.actionButton = .init(isEnabled: true, title: L10n.enterTheAmount)
                    }
                }
            })
            .store(in: &subscriptions)

        $currentToken
            .sink { [weak self] value in
                self?.inputAmountViewModel.token = value
                self?.tokenViewModel.token = value
            }
            .store(in: &subscriptions)
    }
}
