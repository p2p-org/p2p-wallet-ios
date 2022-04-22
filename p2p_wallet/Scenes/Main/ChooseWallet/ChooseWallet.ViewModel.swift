//
//  ChooseWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import BECollectionView
import Foundation
import RxCocoa
import RxSwift

extension ChooseWallet {
    class ViewModel: BEListViewModel<Wallet> {
        // MARK: - Dependencies

        let selectedWallet: Wallet?
        private var myWallets: [Wallet]!
        let handler: WalletDidSelectHandler!
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var tokensRepository: TokensRepository
        @Injected private var analyticsManager: AnalyticsManagerType
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

        override func createRequest() -> Single<[Wallet]> {
            if showOtherWallets {
                return tokensRepository.getTokensList()
                    .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                    .map { $0.excludingSpecialTokens() }
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
                        guard let self = self else { return [] }
                        return self.myWallets + $0
                            .filter { otherWallet in
                                !self.myWallets.contains(where: { $0.token.symbol == otherWallet.token.symbol })
                            }
                    }
                    .observe(on: MainScheduler.instance)
            }
            return .just(myWallets)
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
            pricesService.addToWatchList([wallet.token.symbol])
            pricesService.fetchPrices(tokens: [wallet.token.symbol])
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
