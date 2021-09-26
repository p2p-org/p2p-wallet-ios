//
//  RestoreICloud.AccountsListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import Foundation
import RxSwift
import BECollectionView

protocol AccountsListViewModelType: BEListViewModelType {}

extension RestoreICloud {
    class AccountsListViewModel: BEListViewModel<ParsedAccount> {
        // MARK: - Dependencies
        @Injected private var storage: KeychainAccountStorage
        
        // MARK: - Methods
        override func createRequest() -> Single<[ParsedAccount]> {
            let accountsRequest = Single<[Account]>.just(storage.accountFromICloud() ?? [])
            
            return accountsRequest
                .flatMap {accounts in
                    Single.zip(accounts.map {createAccountSingle(phrase: $0.phrase)})
                        .map {createdAccounts in
                            var parsedAccounts = [ParsedAccount]()
                            for (index, account) in accounts.enumerated() {
                                parsedAccounts.append(.init(account: account, parsedAccount: createdAccounts[index]))
                            }
                            return parsedAccounts
                        }
                }
        }
    }
}

private func createAccountSingle(phrase: String) -> Single<SolanaSDK.Account> {
    Single.create { observer in
        DispatchQueue(label: "createAccount#\(phrase)")
            .async {
                do {
                    let account = try SolanaSDK.Account(
                        phrase: phrase.components(separatedBy: " "),
                        network: Defaults.apiEndPoint.network,
                        derivablePath: .default
                    )
                    observer(.success(account))
                } catch {
                    observer(.failure(error))
                }
                
            }
        return Disposables.create()
    }
}
