//
//  WormholeSendInputView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 22.03.2023.
//

import BigDecimal
import Combine
import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import OrcaSwapSwift
import Resolver
import Send
import SolanaSwift
import Wormhole

class WormholeSendInputViewModel: BaseViewModel, ObservableObject {
    enum Action {
        case openPickAccount
        case openFees
        case send(WormholeSendTransaction)
    }

    enum InputMode {
        case fiat
        case crypto
    }

    let action = PassthroughSubject<Action, Never>()
    let switchPressed = PassthroughSubject<Void, Never>()
    let maxPressed = PassthroughSubject<Void, Never>()

    let solanaAccountsService: SolanaAccountsService

    let stateMachine: WormholeSendInputStateMachine

    @Published var state: WormholeSendInputState

    /// Adapter for state
    var adapter: WormholeSendInputStateAdapter { .init(state: state) }

    // Constants
    let recipient: Recipient

    // Input
    @Published var input: String = ""
    @Published var countAfterDecimalPoint: Int = 8
    @Published var isFirstResponder: Bool = false
    @Published var inputMode: InputMode = .fiat

    // It is needed to display valut with precision in case the max amount is set via fiat mode
    @Published var secondaryAmountString = ""

    // This flag is used to switch input publisher handler because we have already set amounts manually (due to fiat
    // inaccuracy)
    private var wasMaxUsed: Bool = false

    // ActionButton
    @Published var actionButtonData = SliderActionButtonData.zero
    @Published var isSliderOn = false
    @Published var showFinished = false

    init(
        recipient: Recipient,
        userWalletManager: UserWalletManager = Resolver.resolve(),
        wormholeService: WormholeService = Resolver.resolve(),
        relayService: RelayService = Resolver.resolve(),
        relayContextManager: RelayContextManager = Resolver.resolve(),
        orcaSwap: OrcaSwapType = Resolver.resolve(),
        solanaAccountsService: SolanaAccountsService = Resolver.resolve()
    ) {
        self.recipient = recipient
        self.solanaAccountsService = solanaAccountsService

        let services: WormholeSendInputState.Service = (wormholeService, relayService, relayContextManager, orcaSwap)

        // Ensure user wallet is available
        guard let wallet = userWalletManager.wallet else {
            let state: WormholeSendInputState = .unauthorized
            self.state = state
            stateMachine = .init(initialState: state, services: services)
            super.init()
            return
        }

        let availableBridgeAccounts = Self.resolveSupportedSolanaAccounts(solanaAccountsService: solanaAccountsService)

        // Ensure at lease one avaiable wallet for bridging.
        guard let initialSolanaAccount = availableBridgeAccounts.first else {
            let state: WormholeSendInputState = .initializingFailure(
                input: nil,
                error: .missingArguments
            )
            self.state = state
            stateMachine = .init(initialState: state, services: services)
            super.init()
            return
        }

        if initialSolanaAccount.price == nil {
            inputMode = .crypto
        }

        // Setup state machine
        let state: WormholeSendInputState = .calculating(
            newInput: .init(
                solanaAccount: initialSolanaAccount,
                availableAccounts: solanaAccountsService.state.value,
                amount: .init(token: initialSolanaAccount.data.token),
                recipient: recipient.address
            )
        )

        self.state = state
        stateMachine = .init(initialState: state, services: services)

        super.init()

        $isSliderOn
            .sink { value in
                guard value else { return }
                Task { await self.send() }
            }
            .store(in: &subscriptions)

        // Update state machine
        let cryptoInputFormatter = CryptoFormatter(hideSymbol: true)
        let currencyInputFormatter = CurrencyFormatter(hideSymbol: true)

        $input
            .dropFirst()
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sink { [weak self] input in
                guard let self, let account = self.adapter.inputAccount, !self.wasMaxUsed else {
                    self?.wasMaxUsed = false
                    return
                }
                Task {
                    let input = input.replacingOccurrences(of: " ", with: "")
                    var newAmount = input

                    switch self.inputMode {
                    case .fiat:
                        let fiatAmount: CurrencyAmount = .init(usdStr: input)

                        if
                            let price = account.price,
                            let cryptoAmount: CryptoAmount = fiatAmount.toCryptoAmount(price: price)
                        {
                            newAmount = cryptoInputFormatter.string(amount: cryptoAmount)
                            self.secondaryAmountString = cryptoInputFormatter.string(amount: cryptoAmount)
                        } else {
                            newAmount = ""
                            self.secondaryAmountString = ""
                        }

                    case .crypto:
                        if
                            let cryptoAmount = CryptoAmount(floatString: newAmount, token: account.data.token),
                            let price = account.price,
                            let fiatAmount = try? cryptoAmount.toFiatAmount(price: price)
                        {
                            self.secondaryAmountString = currencyInputFormatter.string(amount: fiatAmount)
                        } else {
                            self.secondaryAmountString = ""
                        }
                    }

                    await self.stateMachine.accept(action: .updateInput(amount: newAmount))
                }
            }
            .store(in: &subscriptions)

        stateMachine.state
            .sink { state in
                debugPrint("SendInputState", state)
            }
            .store(in: &subscriptions)

        stateMachine.state
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .weakAssign(to: \.state, on: self)
            .store(in: &subscriptions)

        maxPressed
            .sink { [weak self] _ in
                guard let self, let account = self.adapter.inputAccount else { return }

                let maxAvailableAmount: String
                let secondaryAmount: String

                switch self.inputMode {
                case .fiat:
                    maxAvailableAmount = currencyInputFormatter.string(
                        amount: account.amountInFiat ?? CurrencyAmount(usd: 0)
                    )
                    secondaryAmount = cryptoInputFormatter.string(amount: account.cryptoAmount)
                case .crypto:
                    maxAvailableAmount = cryptoInputFormatter.string(amount: account.cryptoAmount)
                    secondaryAmount = currencyInputFormatter.string(
                        amount: account.amountInFiat ?? CurrencyAmount(usd: 0)
                    )
                }

                self.wasMaxUsed = true
                self.input = maxAvailableAmount
                self.secondaryAmountString = secondaryAmount
            }
            .store(in: &subscriptions)

        switchPressed
            .sink { [weak self] _ in
                guard let self else { return }
                switch self.inputMode {
                case .fiat: self.inputMode = .crypto
                case .crypto: self.inputMode = .fiat
                }
            }
            .store(in: &subscriptions)

        $inputMode
            .sink { [weak self] newMode in
                guard let self, let account = self.adapter.inputAccount else { return }
                switch newMode {
                case .crypto:
                    self.countAfterDecimalPoint = Int(account.data.token.decimals)
                case .fiat:
                    self.countAfterDecimalPoint = 2
                }
            }
            .store(in: &subscriptions)
    }

    func selectSolanaAccount(wallet: Wallet) {
        let accounts = Self.resolveSupportedSolanaAccounts(solanaAccountsService: solanaAccountsService)

        let selectedAccount = accounts.first { account in
            account.data.mintAddress == wallet.mintAddress
        }

        guard let selectedAccount else { return }

        Task { _ = await stateMachine.accept(action: .updateSolanaAccount(account: selectedAccount)) }
    }

    func send() async {
        guard
            case .ready = adapter.state,
            let input = adapter.input,
            let output = adapter.output,
            let transaction = output.transactions
        else {
            return
        }

        showFinished = true

        isFirstResponder = false
        try? await Task.sleep(seconds: 0.5)

        let rawTransaction = WormholeSendTransaction(
            account: input.solanaAccount,
            recipient: recipient,
            amount: input.amount,
            fees: output.fees,
            transaction: transaction
        )

        action.send(.send(rawTransaction))
    }
}

extension WormholeSendInputViewModel {
    static func resolveSupportedSolanaAccounts(
        solanaAccountsService: SolanaAccountsService
    ) -> [SolanaAccountsService.Account] {
        let supportedToken = SupportedToken.bridges.map(\.solAddress).compactMap { $0 }

        var availableBridgeAccounts = solanaAccountsService.state.value.filter { account in
            supportedToken.contains(account.data.token.address)
        }

        if let nativeWallet = solanaAccountsService.state.value.nativeWallet {
            availableBridgeAccounts.append(nativeWallet)
        }

        return availableBridgeAccounts
    }
}
