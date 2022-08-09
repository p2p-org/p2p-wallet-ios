//
//  ChooseWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import AnalyticsManager
import BECollectionView_Combine
import Foundation
import Resolver
import SolanaSwift

extension ChooseWallet {
    class ViewModel: BECollectionViewModel<Wallet> {
        // MARK: - Dependencies

        let selectedWallet: Wallet?
        private var myWallets: [Wallet]!
        let handler: WalletDidSelectHandler!
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var tokensRepository: TokensRepository
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var pricesService: PricesServiceType
        let showOtherWallets: Bool!
        private var keyword: String?

        init(
            selectedWallet: Wallet?,
            handler: WalletDidSelectHandler,
            staticWallets: [Wallet]? = nil,
            showOtherWallets: Bool
        ) {
            self.selectedWallet = selectedWallet
            self.handler = handler
            self.showOtherWallets = showOtherWallets
            super.init()
            myWallets = staticWallets ?? walletsRepository.getWallets()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        // MARK: - Request

        override func createRequest() async throws -> [Wallet] {
            guard showOtherWallets else { return myWallets }

            return try await Task<[Wallet], Error> { [weak self] in
                guard let self = self else { return [] }
                let tokens = Array(try await tokensRepository.getTokensList())
                    .excludingSpecialTokens() // heavy method that needs to be called on different thread
                    .filter {
                        $0.symbol != "SOL"
                    }

                let wallets = tokens
                    .map {
                        Wallet(pubkey: nil, lamports: nil, token: $0)
                    }
                return self.myWallets + wallets
                    .filter { otherWallet in
                        !self.myWallets.contains(where: { $0.token.symbol == otherWallet.token.symbol })
                    }
            }.value
        }

        override func map(newData: [Wallet]) -> [Wallet] {
            var data = super.map(newData: newData)
            if let keyword = keyword {
                data = data.filter { $0.hasKeyword(keyword) }
            }
            return data
        }

        // MARK: - Actions

        func search(keyword: String) {
            guard self.keyword != keyword else { return }
            self.keyword = keyword
            analyticsManager.log(event: .tokenListSearching(searchString: keyword))
            reload()
        }

        func selectWallet(_ wallet: Wallet) {
            analyticsManager.log(event: .tokenChosen(tokenName: wallet.token.symbol))
            handler.walletDidSelect(wallet)
            Task {
                await pricesService.addToWatchList([wallet.token])
                try? await pricesService.fetchPrices(tokens: [wallet.token])
            }
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
