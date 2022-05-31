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

        // MARK: - Properties

        private let disposeBag = DisposeBag()

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
                nameService.getName(account.parsedAccount.publicKey.base58EncodedString)
                    .map {
                        RawAccount(
                            name: $0,
                            phrase: account.parsedAccount.phrase.joined(separator: " "),
                            derivablePath: account.account.derivablePath
                        )
                    }
                    .do(onSuccess: { [weak iCloudStorage] account in
                        _ = iCloudStorage?.saveToICloud(account: account)
                    })
                    .map { newAccountWithName -> RestoreICloud.ParsedAccount in
                        .init(account: newAccountWithName, parsedAccount: account.parsedAccount)
                    }
                    .subscribe(onSuccess: { [weak self] updatedAccount in
                        guard let self = self else { return }
                        self.updateItem { item in
                            item.parsedAccount.publicKey == updatedAccount.parsedAccount.publicKey
                        } transform: { _ in
                            updatedAccount
                        }
                    })
                    .disposed(by: disposeBag)
            }
        }

        private func createParsedAccountSingle(account: RawAccount) -> Single<ParsedAccount> {
            Single<Account>.create { observer in
                DispatchQueue(label: "createAccount#\(account.phrase)", qos: .userInitiated)
                    .async {
                        do {
                            let account = try Account(
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
            .map {
                .init(account: account, parsedAccount: $0)
            }
        }
    }
}
