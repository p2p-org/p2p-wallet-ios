//
//  RestoreICloud.AccountsListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import BECollectionView_Combine
import Foundation
import NameService
import Resolver
import RxSwift
import SolanaSwift

extension RestoreICloud {
    class AccountsListViewModel: BECollectionViewModel<ParsedAccount> {
        // MARK: - Dependencies

        @Injected private var iCloudStorage: ICloudStorageType
        @Injected private var nameService: NameService

        // MARK: - Methods

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        override func createRequest() async throws -> [RestoreICloud.ParsedAccount] {
            let accountsFromICloud = iCloudStorage.accountFromICloud() ?? []
            return try await withThrowingTaskGroup(of: (Int, ParsedAccount).self) { group in
                var accounts = [(Int, ParsedAccount)]()

                for i in 0 ..< accountsFromICloud.count {
                    group.addTask(priority: .userInitiated) {
                        (i, try await self.createParsedAccount(account: accountsFromICloud[i]))
                    }
                }

                for try await(index, account) in group {
                    accounts.append(
                        (index, account)
                    )
                }

                return accounts.sorted(by: { $0.0 < $1.0 }).map(\.1)
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

        private func createParsedAccount(account: RawAccount) async throws -> ParsedAccount {
            let parsedAccount = try await Account(
                phrase: account.phrase.components(separatedBy: " "),
                network: Defaults.apiEndPoint.network,
                derivablePath: account.derivablePath
            )
            return .init(account: account, parsedAccount: parsedAccount)
        }
    }
}
