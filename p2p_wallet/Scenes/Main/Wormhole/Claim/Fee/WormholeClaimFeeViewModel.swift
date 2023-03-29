//
//  WormholeClaimFeeViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 14.03.2023.
//

import BigInt
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Wormhole

class WormholeClaimFeeViewModel: BaseViewModel, ObservableObject {
    typealias Amount = (crypto: String, fiat: String, isFree: Bool)

    let closeAction: PassthroughSubject<Void, Never> = .init()

    @Published var adapter: WormholeClaimFeeAdapter? = nil

    init(
        receive: Amount,
        networkFee: Amount?,
        accountCreationFee: Amount?,
        wormholeBridgeAndTrxFee: Amount?
    ) {
        adapter = .init(
            receive: receive,
            networkFee: networkFee,
            accountCreationFee: accountCreationFee,
            wormholeBridgeAndTrxFee: wormholeBridgeAndTrxFee
        )

        super.init()
    }

    init(
        account: EthereumAccount,
        bundle: AsyncValue<WormholeBundle?>,
        ethereumTokenService: EthereumTokensRepository = Resolver.resolve(),
        solanaTokenService: SolanaTokensRepository = Resolver.resolve()
    ) {
        super.init()

        /// Listen to changing in bundle
        bundle
            .$state
            .sinkAsync { [weak self] state in
                guard let self = self else { return }
                self.adapter = await .init(
                    account: account,
                    state: state,
                    ethereumTokenService: ethereumTokenService,
                    solanaTokenService: solanaTokenService
                )
            }
            .store(in: &subscriptions)
    }

    func close() {
        closeAction.send()
    }
}

extension WormholeClaimViewModel {
    enum ResolveError: Swift.Error {
        case canNotResolveToken
    }

    static func resolveCrytoAmount(
        amount: String,
        feeToken: Wormhole.WormholeToken,
        solanaTokenRepository: TokensRepository = Resolver.resolve(),
        ethereumTokenRepository: EthereumTokensRepository = Resolver.resolve()
    ) async throws -> CryptoAmount {
        switch feeToken {
        case let .solana(address):
            let tokens = try await solanaTokenRepository.getTokensList()
            let token: Token? = tokens.first { $0.address == address }
            guard let token else {
                throw WormholeClaimViewModel.ResolveError.canNotResolveToken
            }

            return CryptoAmount(bigUIntString: amount, token: token)
        case let .ethereum(address):
            if let address {
                let token = try await ethereumTokenRepository.resolve(address: address)
                return CryptoAmount(bigUIntString: amount, token: token)
            } else {
                return CryptoAmount(bigUIntString: amount, token: EthereumToken())
            }
        }
    }
}
