//
//  RestoreICloud.AccountsListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import BECollectionView
import Foundation
import Resolver
import RxSwift
import SolanaSwift

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
            let accountsRequest = Single<[RawAccount]>.just(iCloudStorage.accountFromICloud() ?? [])

            return accountsRequest
                .flatMap { [weak self] accounts in
                    guard let self = self else { throw SolanaError.unknown }
                    return Single
                        .zip(
                            accounts
                                .map { self.createParsedAccountSingle(account: $0) }
                        )
                }
        }

        override func handleNewData(_ newItems: [RestoreICloud.ParsedAccount]) {
            super.handleNewData(newItems)
            updateNames(for: newItems.filter { $0.account.name == nil })
        }

        private func updateNames(for neededNameAccounts: [RestoreICloud.ParsedAccount]) {
            for account in neededNameAccounts {
                Task {
                    let name = try await nameService.getName(account.parsedAccount.publicKey.base58EncodedString)
                    let newAccountWithName = RawAccount(
                        name: name,
                        phrase: account.parsedAccount.phrase.joined(separator: " "),
                        derivablePath: account.account.derivablePath
                    )

                    await MainActor.run { [weak iCloudStorage] in
                        _ = iCloudStorage?.saveToICloud(account: newAccountWithName)
                    }

                    let updatedAccount = RestoreICloud.ParsedAccount(
                        account: newAccountWithName,
                        parsedAccount: account.parsedAccount
                    )

                    await MainActor.run { [weak self] in
                        _ = self?.updateItem { item in
                            item.parsedAccount.publicKey == updatedAccount.parsedAccount.publicKey
                        } transform: { _ in
                            updatedAccount
                        }
                    }
                }
            }
        }

        private func createParsedAccountSingle(account: RawAccount) -> Single<ParsedAccount> {
            Single<Account>.async {
                try await Account(
                    phrase: account.phrase.components(separatedBy: " "),
                    network: Defaults.apiEndPoint.network,
                    derivablePath: account.derivablePath
                )
            }
            .map {
                .init(account: account, parsedAccount: $0)
            }
        }
    }
}
