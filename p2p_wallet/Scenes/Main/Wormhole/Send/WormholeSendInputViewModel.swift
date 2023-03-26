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
            .sink { input in
                Task {
                    let input = input.replacingOccurrences(of: " ", with: "")
                    let _ = await self.stateMachine.accept(action: .updateInput(amount: input))
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
    }

    func maxAction() {
        let maxAvailableAmount = adapter.inputAccount?.cryptoAmount.amount ?? 0
        input = String(maxAvailableAmount)
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
