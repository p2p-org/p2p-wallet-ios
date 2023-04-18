//
//  DetailAccountViewModel.swift
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

enum DetailAccountAction {
    case openBuy
    case openReceive
    case openSend
    case openSwap(Wallet?)
}

class DetailAccountViewModel: BaseViewModel, ObservableObject {
    @Published var rendableAccountDetail: RendableAccountDetail

    let actionSubject: PassthroughSubject<DetailAccountAction, Never>

    init(rendableAccountDetail: RendableAccountDetail) {
        self.rendableAccountDetail = rendableAccountDetail
        actionSubject = .init()
    }

    /// Render solana account and dynamically update it.
    init(
        accountsService: AccountsService = Resolver.resolve(),
        solanaAccount: SolanaAccount,
        jupiterTokensRepository: JupiterTokensRepository = Resolver.resolve()
    ) {
        // Init action subject
        let actionSubject = PassthroughSubject<DetailAccountAction, Never>()
        self.actionSubject = actionSubject

        // Handle action
        let onAction = { [weak actionSubject] (action: RendableAccountDetailAction) in
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
        rendableAccountDetail = RendableNewSolanaAccountDetail(account: solanaAccount, isSwapAvailable: isSwapAvailableDefault, onAction: onAction)

        super.init()

        // Dynamic updating wallet and render it
        accountsService
            .solanaAccountsStatePublisher
            .receive(on: RunLoop.main)
            .map { $0.value.first(where: { $0.data.pubkey == solanaAccount.data.pubkey }) }
            .compactMap { $0 }
            .map {
                RendableNewSolanaAccountDetail(
                    account: $0,
                    isSwapAvailable: isSwapAvailableDefault,
                    onAction: onAction
                )
            }
            .sink { [weak self] rendableAccountDetail in
                self?.rendableAccountDetail = rendableAccountDetail
            }
            .store(in: &subscriptions)
    }
}

extension DetailAccountViewModel {
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
