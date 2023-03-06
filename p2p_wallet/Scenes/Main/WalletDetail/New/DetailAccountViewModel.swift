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

    @Injected private var jupiterTokensRepository: JupiterTokensRepository

    init(rendableAccountDetail: RendableAccountDetail) {
        self.rendableAccountDetail = rendableAccountDetail
        actionSubject = .init()
    }
    
    /// Render solana wallet (account) and dynamically update it.
    init(
        walletsRepository: WalletsRepository = Resolver.resolve(),
        wallet: Wallet
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
        let isSwapAvailableDefault = available(.jupiterSwapEnabled) ? false : true
        rendableAccountDetail = RendableSolanaAccountDetail(wallet: wallet, isSwapAvailable: isSwapAvailableDefault, onAction: onAction)

        super.init()

        // Dynamic updating wallet and render it
        let walletPublisher = walletsRepository.dataPublisher.compactMap { $0.first(where: { $0.pubkey == wallet.pubkey }) }
        Publishers.CombineLatest(walletPublisher, jupiterTokensRepository.status)
            .sink { [weak self] (wallet, status) in
                var isSwapAvailable: Bool = false
                if available(.jupiterSwapEnabled) {
                    switch status {
                    case .ready(let swapTokens, _):
                        if swapTokens.contains(where: { $0.address == wallet.mintAddress }) {
                            isSwapAvailable = true
                        }
                    default:
                        break
                    }
                } else if !available(.jupiterSwapEnabled) {
                    // No restrictions for orca swap
                    isSwapAvailable = true
                }
                self?.rendableAccountDetail = RendableSolanaAccountDetail(wallet: wallet, isSwapAvailable: isSwapAvailable, onAction: onAction)
            }
            .store(in: &subscriptions)
    }
}
