//
//  RecipientsListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/10/2021.
//

import Foundation
import RxSwift
import BECollectionView

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    class RecipientsListViewModel: BEListViewModel<SendToken.Recipient> {
        // MARK: - Dependencies
        @Injected private var nameService: NameServiceType
        @Injected private var addressFormatter: AddressFormatterType
        var solanaAPIClient: SendTokenAPIClient!
        
        // MARK: - Properties
        var searchString: String?

        var isSearchingByAddress: Bool {
            searchString?.count ?? 0 > 40
        }

        // MARK: - Methods
        /// The only methods that MUST be inheritted
        override func createRequest() -> Single<[SendToken.Recipient]> {
            guard let searchString = searchString, !searchString.isEmpty else { return .just([]) }

            return isSearchingByAddress
                ? findRecipientBy(address: searchString)
                : findRecipientsBy(name: searchString)
        }

        private func findRecipientsBy(name: String) -> Single<[SendToken.Recipient]> {
            nameService
                .getOwners(name)
                .map { [weak addressFormatter] in
                    guard let addressFormatter = addressFormatter else { return [] }

                    return $0.map {
                        SendToken.Recipient(
                            address: $0.owner,
                            shortAddress: addressFormatter.shortAddress(of: $0.owner),
                            name: $0.name,
                            hasNoFunds: false
                        )
                    }
                }
        }

        private func findRecipientBy(address: String) -> Single<[SendToken.Recipient]> {
            nameService
                .getName(address)
                .flatMap {[weak self] name -> Single<(String?, Bool)> in
                    guard let self = self, name == nil else {return .just((name, false))}
                    // check funds
                    return self.solanaAPIClient.checkAccountValidation(account: address)
                        .catchAndReturn(false)
                        .map {(name, !$0)}
                }
                .map { [weak addressFormatter] in
                    guard let addressFormatter = addressFormatter else { return [] }

                    let recipient = SendToken.Recipient(
                        address: address,
                        shortAddress: addressFormatter.shortAddress(of: address),
                        name: $0.0,
                        hasNoFunds: $0.1
                    )

                    return [recipient]
                }
        }
    }
}
