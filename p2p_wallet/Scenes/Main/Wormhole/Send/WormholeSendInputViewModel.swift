//
//  WormholeSendInputView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 22.03.2023.
//

import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Send
import SolanaSwift
import Wormhole
import BigDecimal

class WormholeSendInputViewModel: BaseViewModel, ObservableObject {
    enum Action {
        case openPickAccount
        case openFees
        case send(PendingTransaction)
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
    var adapter: WormholeSendInputStateAdapter {
        .init(state: state)
    }

    // Constants
    let recipient: Recipient

    // Input
    @Published var input: String = ""
    @Published var countAfterDecimalPoint: Int = 8
    @Published var isFirstResponder: Bool = false
    @Published var inputMode: InputMode = .fiat
    @Published var secondaryAmountString = "" // It is needed to display valut with precision in case the max amount is set via fiat mode

    // This flag is used to switch input publisher handler because we have already set amounts manually (due to fiat inaccuracy)
    private var wasMaxUsed: Bool = false

    // ActionButton
    @Published var actionButtonData = SliderActionButtonData.zero
    @Published var isSliderOn = false
    @Published var showFinished = false

    init(
        recipient: Recipient,
        userWalletManager: UserWalletManager = Resolver.resolve(),
        wormholeService: WormholeService = Resolver.resolve(),
        solanaAccountsService: SolanaAccountsService = Resolver.resolve()
    ) {
        self.recipient = recipient
        self.solanaAccountsService = solanaAccountsService

        // Ensure user wallet is available
        guard let wallet = userWalletManager.wallet else {
            let state: WormholeSendInputState = .unauthorized
            self.state = state
            stateMachine = .init(initialState: state, services: wormholeService)
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
            stateMachine = .init(initialState: state, services: wormholeService)
            super.init()
            return
        }

        // Setup state machine
        let state: WormholeSendInputState = .initializing(
            input: .init(
                solanaAccount: initialSolanaAccount,
                amount: .init(amount: 0, token: initialSolanaAccount.data.token),
                recipient: recipient.address,
                feePayer: wallet.account.publicKey.base58EncodedString
            )
        )
        self.state = state
        stateMachine = .init(
            initialState: state,
            services: wormholeService
        )

        super.init()

        $isSliderOn
            .sink { value in
                guard value else { return }
                Task { await self.send() }
            }
            .store(in: &subscriptions)

        // Update state machine
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
                    if self.inputMode == .fiat {
                        let fiatAmount = CurrencyAmount(usdStr: input)
                        let cryptoAmount = fiatAmount.toCryptoAmount(account: account)
                        let _ = await self.stateMachine.accept(action: .updateInput(amount: String(self.adapter.cryptoFormatter.string(amount: cryptoAmount).split(separator: " ")[0])))
                        self.secondaryAmountString = self.adapter.cryptoFormatter.string(amount: cryptoAmount, withCode: false)
                    } else {
                        let _ = await self.stateMachine.accept(action: .updateInput(amount: input))
                        self.secondaryAmountString = self.adapter.currencyFormatter.string(amount: account.amountInFiat ?? CurrencyAmount(usd: 0), withCode: false)
                    }
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
                switch self.inputMode {
                case .fiat:
                    maxAvailableAmount = self.adapter.currencyFormatter.string(amount: account.amountInFiat ?? CurrencyAmount(usd: 0), withCode: false)
                    self.secondaryAmountString = self.adapter.cryptoFormatter.string(amount: account.cryptoAmount, withCode: false)
                case .crypto:
                    maxAvailableAmount = self.adapter.cryptoFormatter.string(amount: account.cryptoAmount, withCode: false)
                    self.secondaryAmountString = self.adapter.currencyFormatter.string(amount: account.amountInFiat ?? CurrencyAmount(usd: 0), withCode: false)
                }
                self.wasMaxUsed = true
                self.input = maxAvailableAmount
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
            let output = adapter.output
        else {
            return
        }

        showFinished = true

        let rawTransaction = WormholeSendTransaction(
            account: input.solanaAccount,
            recipient: input.recipient,
            amount: input.amount,
            fees: output.fees
        )

        let transactionHandler: TransactionHandler = Resolver.resolve()
        let index = transactionHandler.sendTransaction(rawTransaction)
        let pendingTransaction = transactionHandler.getProcessingTransaction(index: index)

        action.send(.send(pendingTransaction))
    }
}

extension WormholeSendInputViewModel {
    static func resolveSupportedSolanaAccounts(
        solanaAccountsService: SolanaAccountsService = Resolver.resolve()
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
