//
//  RestoreICloud.AccountsListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import BECollectionView
import Foundation
import RxSwift

protocol AccountsListViewModelType: BEListViewModelType {}

extension RestoreICloud {
    class AccountsListViewModel: BEListViewModel<ParsedAccount> {
        // MARK: - Dependencies

        @Injected private var iCloudStorage: ICloudStorageType
        @Injected private var nameService: NameServiceType

        // MARK: - Methods

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        override func createRequest() -> Single<[ParsedAccount]> {
            let accountsRequest = Single<[Account]>.just(iCloudStorage.accountFromICloud() ?? [])

            return accountsRequest
                .flatMap { [weak self] accounts in
                    guard let self = self else { throw SolanaSDK.Error.unknown }
                    return Single.zip(accounts.map { createAccountSingle(account: $0, nameService: self.nameService, storage: self.iCloudStorage) })
                }
        }
    }
}

private func createAccountSingle(account: Account, nameService: NameServiceType, storage: ICloudStorageType) -> Single<RestoreICloud.ParsedAccount> {
    createSolanaAccountSingle(account: account)
        .flatMap { solanaAccount -> Single<RestoreICloud.ParsedAccount> in
            let accountRequest: Single<Account>
            if account.name != nil {
                accountRequest = .just(account)
            } else {
                accountRequest = nameService.getName(solanaAccount.publicKey.base58EncodedString)
                    .map { Account(name: $0, phrase: account.phrase, derivablePath: account.derivablePath) }
                    .do(onSuccess: { [weak storage] account in
                        _ = storage?.saveToICloud(account: account)
                    })
                    .catchAndReturn(account)
            }
            return accountRequest
                .map { .init(account: $0, parsedAccount: solanaAccount) }
        }
}

private func createSolanaAccountSingle(account: Account) -> Single<SolanaSDK.Account> {
    Single.create { observer in
        DispatchQueue(label: "createAccount#\(account.phrase)")
            .async {
                do {
                    let account = try SolanaSDK.Account(
                        phrase: account.phrase.components(separatedBy: " "),
                        network: Defaults.apiEndPoint.network,
                        derivablePath: account.derivablePath
                    )
                    observer(.success(account))
                } catch {
                    observer(.failure(error))
                }
            }
        return Disposables.create()
    }
}
