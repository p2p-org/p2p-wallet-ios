//
//  AccountDetailsViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Combine
import Foundation
import KeyAppKitCore
import KeyAppBusiness
import Resolver
import SolanaSwift

enum AccountDetailsAction {
    case openBuy
    case openReceive
    case openSend
    case openSwap(Wallet?)
}

class AccountDetailsViewModel: BaseViewModel, ObservableObject {
    @Published var rendableAccountDetails: RendableAccountDetails

    let actionSubject: PassthroughSubject<AccountDetailsAction, Never>

    init(rendableAccountDetails: RendableAccountDetails) {
        self.rendableAccountDetails = rendableAccountDetails
        actionSubject = .init()
    }

    /// Render solana account and dynamically update it.
    init(
        accountsService: AccountsService = Resolver.resolve(),
        solanaAccount: SolanaAccount,
        jupiterTokensRepository: JupiterTokensRepository = Resolver.resolve()
    ) {
        // Init action subject
        let actionSubject = PassthroughSubject<AccountDetailsAction, Never>()
        self.actionSubject = actionSubject

        // Handle action
        let onAction = { [weak actionSubject] (action: RendableAccountDetailsAction) in
            switch action {
            case .buy:
                actionSubject?.send(.openBuy)
            case .swap:
                actionSubject?.send(.openSwap(solanaAccount.data))
            case .send:
                actionSubject?.send(.openSend)
            case .receive:
                actionSubject?.send(.openReceive)
            }
        }

        // Render solana wallet (account)
        let isSwapAvailableDefault = available(.jupiterSwapEnabled) ? false : true
        rendableAccountDetails = RendableNewSolanaAccountDetails(account: solanaAccount, isSwapAvailable: isSwapAvailableDefault, onAction: onAction)

        super.init()

        // Dynamic updating wallet and render it
        accountsService
            .solanaAccountsStatePublisher
            .receive(on: RunLoop.main)
            .map { $0.value.first(where: { $0.data.pubkey == solanaAccount.data.pubkey }) }
            .compactMap { $0 }
            .map {
                RendableNewSolanaAccountDetails(
                    account: $0,
                    isSwapAvailable: isSwapAvailableDefault,
                    onAction: onAction
                )
            }
            .sink { [weak self] rendableAccountDetails in
                self?.rendableAccountDetails = rendableAccountDetails
            }
            .store(in: &subscriptions)
    }
}

extension AccountDetailsViewModel {
    /// Check swap action is available for this account (wallet).
    static func isSwapAvailableFor(wallet: Wallet, for status: JupiterDataStatus) -> Bool {
        if available(.jupiterSwapEnabled) {
            switch status {
            case .ready(let swapTokens, _) where swapTokens.contains(where: { $0.address == wallet.mintAddress }):
                return true
            default:
                return false
            }
        } else {
            return true
        }
    }
}
