//
//  AccountsListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/05/2021.
//

import Foundation
import RxSwift
import BECollectionView

extension DerivableAccountsViewModel {
    class AccountsListViewModel: BEListViewModel<DerivableAccount> {
        private let phrases: [String]
        private let pricesFetcher: PricesFetcher
        var derivablePath: Path?
        
        init(phrases: [String], pricesFetcher: PricesFetcher) {
            self.phrases = phrases
            self.pricesFetcher = pricesFetcher
            super.init(initialData: [])
        }
        override func createRequest() -> Single<[DerivableAccount]> {
            Single.zip(Array(0..<10)
                .map {
                    createAccountSingle(index: $0)
                        .map {DerivableAccount(info: $0, amount: 0)}
                }
            )
                .observe(on: MainScheduler.instance)
        }
        
        private func createAccountSingle(index: Int) -> Single<SolanaSDK.Account> {
            Single.create { [weak self] observer in
                DispatchQueue(label: "createAccount#\(index)")
                    .async { [weak self] in
                        print("creating account #\(index)")
                        guard let strongSelf = self, let path = strongSelf.derivablePath else {
                            observer(.failure(SolanaSDK.Error.unknown))
                            return
                        }
                        
                        do {
                            let account = try SolanaSDK.Account(
                                phrase: strongSelf.phrases,
                                network: Defaults.apiEndPoint.network,
                                derivablePath: Path(type: path.type, walletIndex: index)
                            )
                            print("successfully created account #\(index)")
                            observer(.success(account))
                        } catch {
                            observer(.failure(error))
                        }
                        
                    }
                return Disposables.create()
            }
        }
        
    }
}
