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
import Wormhole

class WormholeSendInputViewModel: BaseViewModel, ObservableObject {
    enum InputMode {
        case fiat
        case crypto
    }

    let changeTokenPressed = PassthroughSubject<Void, Never>()

    let stateMachine: WormholeSendInputStateMachine

    @Published var state: WormholeSendInputState
    var adapter: WormholeSendInputStateAdapter {
        .init(state: state)
    }

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
        // Ensure user wallet is available
        guard let wallet = userWalletManager.wallet else {
            let state: WormholeSendInputState = .unauthorized
            self.state = state
            stateMachine = .init(initialState: state, services: wormholeService)
            super.init()
            return
        }

        let supportedToken = SupportedToken.bridges.map(\.solAddress).compactMap { $0 }

        var availableBridgeAccounts = solanaAccountsService.state.value.filter { account in
            supportedToken.contains(account.data.token.address)
        }

        if let nativeWallet = solanaAccountsService.state.value.nativeWallet {
            availableBridgeAccounts.append(nativeWallet)
        }

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
                amount: 0,
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

        $input
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sink { input in
                Task {
                    let input = input.replacingOccurrences(of: " ", with: "")
                    await self.stateMachine.accept(action: .updateInput(amount: input))
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
}

struct WormholeSendInputStateAdapter {
    let cryptoFormatter: CryptoFormatter = .init()
    let currencyFormatter: CurrencyFormatter = .init()

    var state: WormholeSendInputState

    var input: WormholeSendInputBase? {
        switch state {
        case let .initializing(input):
            return input
        case let .ready(input, output, alert):
            return input
        case let .calculating(newInput):
            return newInput
        case let .error(input, output, error):
            return input
        case .unauthorized, .initializingFailure:
            return nil
        }
    }

    var inputAccount: SolanaAccountsService.Account? {
        return input?.solanaAccount
    }

    var selectedToken: SolanaToken {
        inputAccount?.data.token ?? .nativeSolana
    }

    var inputAccountSkeleton: Bool {
        inputAccount == nil
    }

    private var cryptoAmount: CryptoAmount {
        guard let input = input else {
            return .init(amount: 0, token: SolanaToken.nativeSolana)
        }

        return .init(amount: input.amount, token: input.solanaAccount.data.token)
    }

    var amountInFiatString: String {
        guard
            let price = input?.solanaAccount.price,
            let currencyAmount = try? cryptoAmount.toFiatAmount(price: price)
        else { return "" }

        return currencyFormatter.string(amount: currencyAmount)
    }

    var fees: String {
        switch state {
        case let .initializing(input):
            return ""
        case let .ready(input, output, alert):
            return "Fees: \(currencyFormatter.string(amount: output.fees.totalInFiat))"
        case let .calculating(newInput):
            return ""
        case let .error(input, output, error):
            if let output {
                return "Fees: \(currencyFormatter.string(amount: output.fees.totalInFiat))"
            } else {
                return ""
            }
        case .unauthorized, .initializingFailure:
            return ""
        }
    }

    var feesLoading: Bool {
        switch state {
        case let .initializing(input):
            return true
        case let .ready(input, output, alert):
            return false
        case let .calculating(newInput):
            return true
        case let .error(input, output, error):
            return false
        case .unauthorized, .initializingFailure:
            return false
        }
    }
}
