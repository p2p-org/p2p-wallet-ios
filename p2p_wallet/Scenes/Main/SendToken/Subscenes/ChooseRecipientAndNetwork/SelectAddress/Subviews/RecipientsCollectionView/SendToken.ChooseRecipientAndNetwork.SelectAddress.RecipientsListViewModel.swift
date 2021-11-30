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
    class RecipientsListViewModel: BEListViewModel<Recipient> {
        // MARK: - Dependencies
        @Injected private var nameService: NameServiceType
        @Injected private var addressFormatter: AddressFormatterType
        
        // MARK: - Properties
        var searchString: String?

        var isSearchingByAddress: Bool {
            searchString?.count ?? 0 > 40
        }

        // MARK: - Methods
        /// The only methods that MUST be inheritted
        override func createRequest() -> Single<[Recipient]> {
            guard let searchString = searchString, !searchString.isEmpty else { return .just([]) }

            return isSearchingByAddress
                ? findRecipientBy(address: searchString)
                : findRecipientsBy(name: searchString)
        }

        private func findRecipientsBy(name: String) -> Single<[Recipient]> {
            nameService
                .getOwners(name)
                .map { [weak addressFormatter] in
                    guard let addressFormatter = addressFormatter else { return [] }

                    return $0.map {
                        Recipient(
                            address: $0.owner,
                            shortAddress: addressFormatter.shortAddress(of: $0.owner),
                            name: $0.name
                        )
                    }
                }
        }

        private func findRecipientBy(address: String) -> Single<[Recipient]> {
            nameService
                .getName(address)
                .map { [weak addressFormatter] in
                    guard let addressFormatter = addressFormatter else { return [] }

                    let recipient = Recipient(
                        address: address,
                        shortAddress: addressFormatter.shortAddress(of: address),
                        name: $0
                    )

                    return [recipient]
                }
        }
    }
}
