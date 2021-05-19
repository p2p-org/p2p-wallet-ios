//
//  AccountsListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/05/2021.
//

import Foundation
import RxSwift
import BECollectionView
import RxAlamofire

extension DerivableAccountsViewModel {
    class AccountsListViewModel: BEListViewModel<DerivableAccount> {
        private let phrases: [String]
        private let pricesFetcher: PricesFetcher
        var derivablePath: Path?
        let disposeBag = DisposeBag()
        var balanceCache = [String: Double]() // PublicKey: Balance
        var priceCache: Double?
        
        init(phrases: [String], pricesFetcher: PricesFetcher) {
            self.phrases = phrases
            self.pricesFetcher = pricesFetcher
            super.init(initialData: [])
        }
        override func createRequest() -> Single<[DerivableAccount]> {
            Single.zip(Array(0..<5)
                .map {
                    createAccountSingle(index: $0)
                        .map {
                            DerivableAccount(
                                info: $0,
                                amount: self.balanceCache[$0.publicKey.base58EncodedString],
                                price: self.priceCache
                            )
                        }
                }
            )
                .do(onSuccess: {[weak self] accounts in
                    self?.fetchSOLPrice()
                    for account in accounts {
                        self?.fetchBalances(account: account.info.publicKey.base58EncodedString)
                    }
                })
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
        
        private func fetchSOLPrice() {
            if priceCache != nil {return}
            pricesFetcher.getCurrentPrices(coins: ["SOL"], toFiat: Defaults.fiat.code)
                .map {$0.first?.value?.value ?? 0}
                .do(onSuccess: { [weak self] in
                    if $0 != 0 {
                        self?.priceCache = $0
                    }
                })
                .subscribe(onSuccess: { [weak self] price in
                    guard let strongSelf = self, strongSelf.currentState == .loaded else {return}
                
                    let data = strongSelf.data.map { account -> DerivableAccount in
                        var account = account
                        account.price = price
                        return account
                    }
                    strongSelf.overrideData(by: data)
                })
                .disposed(by: disposeBag)
        }
        
        private func fetchBalances(account: String) {
            if balanceCache[account] != nil {
                return
            }
            
            let bcMethod = "getBalance"
            
            let requestAPI = SolanaSDK.RequestAPI(method: bcMethod, params: [account])
            
            do {
                var urlRequest = try URLRequest(url: SolanaSDK.APIEndPoint.definedEndpoints.first!.url, method: .post, headers: [.contentType("application/json")])
                urlRequest.httpBody = try JSONEncoder().encode(requestAPI)
                
                RxAlamofire.request(urlRequest)
                    .validate(statusCode: 200..<300)
                    .responseData()
                    .map {(response, data) -> SolanaSDK.Rpc<UInt64> in
                        // Print
                        Logger.log(message: String(data: data, encoding: .utf8) ?? "", event: .response, apiMethod: bcMethod)
                        
                        // Print
                        let response = try JSONDecoder().decode(SolanaSDK.Response<SolanaSDK.Rpc<UInt64>>.self, from: data)
                        if let result = response.result {
                            return result
                        }
                        if let error = response.error {
                            throw SolanaSDK.Error.invalidResponse(error)
                        }
                        throw SolanaSDK.Error.unknown
                    }
                    .map {$0.value.convertToBalance(decimals: 9)}
                    .take(1)
                    .asSingle()
                    .do(onSuccess: {[weak self] in self?.balanceCache[account] = $0})
                    .subscribe(onSuccess: { [weak self] amount in
                        self?.updateItem(where: {$0.info.publicKey.base58EncodedString == account}, transform: { account in
                            var account = account
                            account.amount = amount
                            return account
                        })
                    })
                    .disposed(by: disposeBag)
            } catch {
                return
            }
        }
    }
}
