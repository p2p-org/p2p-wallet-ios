//
//  WormholeSendInputView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 22.03.2023.
//

import Foundation
import KeyAppBusiness
import Resolver
import Send
import Wormhole

class WormholeSendInputViewModel: BaseViewModel, ObservableObject {
    let stateMachine: WormholeSendInputStateMachine

    @Published var state: WormholeSendInputState

    // Input
    @Published var input: String = ""
    @Published var countAfterDecimalPoint: Int = 8
    @Published var isFirstResponder: Bool = false

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
            let state: WormholeSendInputState = .initializingFailure(error: .missingArguments)
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

        Task {
            let _ = await stateMachine.accept(action: .initialize)
        }

        $input
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sink { input in
                Task {
                    let input = input.replacingOccurrences(of: " ", with: "")
                    await self.stateMachine.accept(action: .updateInput(amount: BigUInt(input, radix: 10) ?? 0))
                    // TODO: Remove it, just for testing
//                    self.actionButtonData = Double(input) > 0 ? SliderActionButtonData(isEnabled: true, title: L10n.send(input, "WETH")) : SliderActionButtonData.zero
                }
            }
            .store(in: &subscriptions)

        stateMachine.state
            .sink { state in
                print("SendInputState", state)
            }
            .store(in: &subscriptions)

        stateMachine.state
            .receive(on: RunLoop.main)
            .weakAssign(to: \.state, on: self)
            .store(in: &subscriptions)
    }
}
