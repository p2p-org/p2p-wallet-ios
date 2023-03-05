//
//  DetailAccountViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Combine
import Foundation
import Resolver
import SolanaSwift

enum DetailAccountAction {
    case openBuy
    case openReceive
    case openSend
    case openSwap
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
        solanaAccountsManager: SolanaAccountsManager = Resolver.resolve(),
        solanaAccount: SolanaAccountsManager.Account
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
                actionSubject?.send(.openSwap)
            case .send:
                actionSubject?.send(.openSend)
            case .receive:
                actionSubject?.send(.openReceive)
            }
        }

        // Render solana wallet (account)
        rendableAccountDetail = RendableNewSolanaAccountDetail(account: solanaAccount, onAction: onAction)

        super.init()

        // Dynamic updating wallet and render it
        solanaAccountsManager
            .$state
            .receive(on: RunLoop.main)
            .map { $0.item.first(where: { $0.data.pubkey == solanaAccount.data.pubkey }) }
            .compactMap { $0 }
            .map { RendableNewSolanaAccountDetail(account: $0, onAction: onAction) }
            .sink { [weak self] rendableAccountDetail in
                self?.rendableAccountDetail = rendableAccountDetail
            }
            .store(in: &subscriptions)
    }
}
