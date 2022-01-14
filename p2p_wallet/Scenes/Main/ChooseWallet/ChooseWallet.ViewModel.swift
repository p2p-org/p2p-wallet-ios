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
        let selectedWallet: Wallet?
        private var myWallets: [Wallet]!
        let handler: WalletDidSelectHandler!
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var tokensRepository: TokensRepository
        let showOtherWallets: Bool!
        private var keyword: String?
    
        init(
            selectedWallet: Wallet?,
            handler: WalletDidSelectHandler,
            showOtherWallets: Bool
        ) {
            self.selectedWallet = selectedWallet
            self.handler = handler
            self.showOtherWallets = showOtherWallets
            super.init()
            self.myWallets = walletsRepository.getWallets()
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        // MARK: - Request
        override func createRequest() -> Single<[Wallet]> {
            if showOtherWallets {
                return tokensRepository.getTokensList()
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
                    .map { [weak self] in
                        guard let self = self else {return []}
                        return self.myWallets + $0.filter {otherWallet in !self.myWallets.contains(where: {$0.token.symbol == otherWallet.token.symbol})}
                    }
            }
            return .just(myWallets)
        }
        
        override func map(newData: [Wallet]) -> [Wallet] {
            var data = super.map(newData: newData)
            if let keyword = keyword {
                data = data.filter {$0.hasKeyword(keyword)}
            }
            return data
        }
        
        // MARK: - Actions
        func search(keyword: String) {
            guard self.keyword != keyword else {return}
            self.keyword = keyword
            reload()
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
