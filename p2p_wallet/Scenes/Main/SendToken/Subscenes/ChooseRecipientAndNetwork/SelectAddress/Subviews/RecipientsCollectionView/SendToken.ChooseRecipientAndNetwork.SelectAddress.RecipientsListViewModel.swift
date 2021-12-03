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
        var solanaAPIClient: SendTokenAPIClient!
        
        // MARK: - Properties
        var searchString: String?

        var isSearchingByAddress: Bool {
            searchString?.matches(oneOf: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet()), .publicKey) == true
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
                .map {
                    $0.map {
                        .init(
                            address: $0.owner,
                            name: $0.name,
                            hasNoFunds: false
                        )
                    }
                }
        }

        private func findRecipientBy(address: String) -> Single<[SendToken.Recipient]> {
            if NSRegularExpression.bitcoinAddress(isTestnet: solanaAPIClient.isTestNet()).matches(address) {
                return .just([.init(address: address, name: nil, hasNoFunds: false)])
            }
            return nameService
                .getName(address)
                .flatMap {[weak self] name -> Single<(String?, Bool)> in
                    guard let self = self, name == nil else {return .just((name, false))}
                    // check funds
                    return self.solanaAPIClient.checkAccountValidation(account: address)
                        .catchAndReturn(false)
                        .map {(name, !$0)}
                }
                .map {
                    [
                        .init(
                            address: address,
                            name: $0.0,
                            hasNoFunds: $0.1
                        )
                    ]
                }
                .catchAndReturn([
                    .init(
                        address: address,
                        name: nil,
                        hasNoFunds: false,
                        hasNoInfo: true
                    )
                ])
        }
    }
}
