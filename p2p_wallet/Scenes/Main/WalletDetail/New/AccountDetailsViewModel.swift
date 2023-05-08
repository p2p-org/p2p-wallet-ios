//
//  AccountDetailsViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Combine
import Foundation
import KeyAppBusiness
import Resolver
import SolanaSwift
import KeyAppKitCore

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
        solanaAccountsManager: SolanaAccountsService = Resolver.resolve(),
        solanaAccount: SolanaAccountsService.Account,
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
                actionSubject?.send(.openSwap(solanaAccount))
            case .send:
                actionSubject?.send(.openSend)
            case .receive:
                actionSubject?.send(.openReceive)
            }
        }

        // Render solana wallet (account)
        rendableAccountDetails = RendableNewSolanaAccountDetails(account: solanaAccount, isSwapAvailable: false, onAction: onAction)

        super.init()

        // Dynamic updating wallet and render it
        let solanaAccountPublisher = solanaAccountsManager
            .statePublisher
            .receive(on: RunLoop.main)
            .compactMap { $0.value.first(where: { $0.pubkey == solanaAccount.pubkey }) }
        
        let jupiterDataStatusPublisher = jupiterTokensRepository.status
        
        Publishers.CombineLatest(solanaAccountPublisher, jupiterDataStatusPublisher)
            .map { account, status in
                RendableNewSolanaAccountDetails(
                    account: account,
                    isSwapAvailable: Self.isSwapAvailableFor(wallet: account, for: status),
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
        switch status {
        case .ready(let swapTokens, _) where swapTokens.contains(where: { $0.address == wallet.mintAddress }):
            return true
        default:
            return false
        }
    }
}
