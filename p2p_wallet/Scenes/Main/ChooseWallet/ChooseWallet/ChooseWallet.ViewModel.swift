//
//  ChooseWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import Foundation
import RxSwift
import RxCocoa
import BECollectionView

extension ChooseWallet {
    class ViewModel: BEListViewModel<Wallet> {
        // MARK: - Dependencies
        private let myWallets: [Wallet]
        private let handler: WalletDidSelectHandler
        private let tokensRepository: TokensRepository
        
        init(
            myWallets: [Wallet],
            handler: WalletDidSelectHandler,
            tokensRepository: TokensRepository
        ) {
            self.myWallets = myWallets
            self.handler = handler
            self.tokensRepository = tokensRepository
            super.init()
            reload()
        }
        
        // MARK: - Request
        override func createRequest() -> Single<[Wallet]> {
            tokensRepository.getTokensList()
                .map {$0.excludingSpecialTokens()}
                .map {
                    $0
                        .filter {
                            $0.symbol != "SOL"
                        }
                        .map {
                            Wallet(pubkey: nil, lamports: nil, token: $0)
                        }
                }
                .map {
                    self.myWallets + $0
                }
        }
        
        // MARK: - Actions
        func search(keyword: String) {
            
        }
        
        func selectWallet(_ wallet: Wallet) {
            handler.walletDidSelect(wallet)
        }
    }
}

private extension Wallet {
    func hasKeyword(_ keyword: String) -> Bool {
        token.symbol.lowercased().hasPrefix(keyword.lowercased()) ||
            token.symbol.lowercased().contains(keyword.lowercased()) ||
            token.name.lowercased().hasPrefix(keyword.lowercased()) ||
            token.name.lowercased().contains(keyword.lowercased())
    }
}
