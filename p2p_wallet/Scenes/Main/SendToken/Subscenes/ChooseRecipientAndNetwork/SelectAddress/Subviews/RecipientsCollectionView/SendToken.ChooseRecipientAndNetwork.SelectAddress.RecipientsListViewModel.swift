//
//  RecipientsListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/10/2021.
//

import BECollectionView_Combine
import Foundation
import NameService
import Resolver

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    class RecipientsListViewModel: BECollectionViewModel<SendToken.Recipient> {
        // MARK: - Dependencies

        @Injected private var nameService: NameService
        var solanaAPIClient: SendServiceType!
        var preSelectedNetwork: SendToken.Network!

        // MARK: - Properties

        var searchString: String?

        private let addressSize = 44
        var isSearchingByAddress: Bool {
            searchString?
                .matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet()), .publicKey) == true
        }

        // MARK: - Methods

        /// The only methods that MUST be inheritted
        override func createRequest() async throws -> [SendToken.Recipient] {
            guard let searchString = searchString, !searchString.isEmpty else { return [] }
            // force find by address when network is bitcoin
            return preSelectedNetwork == .bitcoin || isSearchingByAddress
                ? (try await findRecipientBy(address: searchString))
                : (try await findRecipientsBy(name: searchString))
        }

        private func findRecipientsBy(name: String) async throws -> [SendToken.Recipient] {
            try await nameService.getOwners(name).map {
                .init(
                    address: $0.owner,
                    name: $0.name,
                    hasNoFunds: false
                )
            }
        }

        private func findRecipientBy(address: String) async throws -> [SendToken.Recipient] {
            switch preSelectedNetwork {
            case .bitcoin:
                return try await findAddressInBitcoinNetwork(address: address)
            case .solana:
                return try await findAddressInSolanaNetwork(address: address)
            case .none:
                if address.matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet())) {
                    return try await findAddressInBitcoinNetwork(address: address)
                } else {
                    return try await findAddressInSolanaNetwork(address: address)
                }
            }
        }

        private func findAddressInBitcoinNetwork(address: String) async throws -> [SendToken.Recipient] {
            if address.matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet())) {
                return [.init(address: address, name: nil, hasNoFunds: false)]
            } else {
                return []
            }
        }

        private func findAddressInSolanaNetwork(address: String) async throws -> [SendToken.Recipient] {
//            Single<Bool>.async { [weak self] in
//                (try? await self?.solanaAPIClient.checkAccountValidation(account: address)) ?? false
//            }.map {
//                [
//                    .init(
//                        address: address,
//                        name: nil,
//                        hasNoFunds: $0
//                    ),
//                ]

            // NameService is currently disabled
//            do {
//                let name = try await nameService.getName(address)

//                if let name = name {
//                    return [
//                        .init(
//                            address: address,
//                            name: name.withNameServiceDomain(),
//                            hasNoFunds: false
//                        ),
//                    ]
//                } else {
            let isValid = (try? await solanaAPIClient.checkAccountValidation(account: address)) ?? false
            return [
                .init(
                    address: address,
                    name: nil,
                    hasNoFunds: !isValid
                ),
            ]
//                }
//            } catch {
//                return [.init(
//                    address: address,
//                    name: nil,
//                    hasNoFunds: false,
//                    hasNoInfo: true
//                )]
//            }
        }
    }
}
