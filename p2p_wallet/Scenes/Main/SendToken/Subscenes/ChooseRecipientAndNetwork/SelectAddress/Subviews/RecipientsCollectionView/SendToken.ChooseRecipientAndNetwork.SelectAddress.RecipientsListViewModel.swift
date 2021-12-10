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
        var preSelectedNetwork: SendToken.Network!
        
        // MARK: - Properties
        var searchString: String?

        var isSearchingByAddress: Bool {
            searchString?.matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet()), .publicKey) == true
        }

        // MARK: - Methods
        /// The only methods that MUST be inheritted
        override func createRequest() -> Single<[SendToken.Recipient]> {
            guard let searchString = searchString, !searchString.isEmpty else { return .just([]) }

            // force find by address when network is bitcoin
            return preSelectedNetwork == .bitcoin || isSearchingByAddress
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
            switch preSelectedNetwork {
            case .bitcoin:
                return findAddressInBitcoinNetwork(address: address)
            case .solana:
                return findAddressInSolanaNetwork(address: address)
            case .none:
                if address.matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet()))
                {
                    return findAddressInBitcoinNetwork(address: address)
                } else {
                    return findAddressInSolanaNetwork(address: address)
                }
            }
        }
        
        private func findAddressInBitcoinNetwork(address: String) -> Single<[SendToken.Recipient]> {
            if address.matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet())) {
                return .just([.init(address: address, name: nil, hasNoFunds: false)])
            } else {
                return .just([])
            }
        }
        
        private func findAddressInSolanaNetwork(address: String) -> Single<[SendToken.Recipient]> {
            nameService
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
                            name: $0.0?.withNameServiceDomain(),
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
