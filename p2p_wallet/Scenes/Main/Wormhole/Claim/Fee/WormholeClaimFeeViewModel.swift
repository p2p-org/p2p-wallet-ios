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

    @Published var adapter: AsyncValueState<WormholeClaimFeeAdapter?> = .init(value: nil)

    init(
        receive: Amount,
        networkFee: Amount,
        accountCreationFee: Amount?,
        wormholeBridgeAndTrxFee: Amount
    ) {
        adapter = .init(
            status: .ready,
            value: .init(
                receive: receive,
                networkFee: networkFee,
                accountCreationFee: accountCreationFee,
                wormholeBridgeAndTrxFee: wormholeBridgeAndTrxFee
            )
        )

        super.init()
    }

    init(
        account: EthereumAccount,
        bundle: AsyncValue<WormholeBundle?>,
        ethereumTokenService _: EthereumTokensRepository = Resolver.resolve(),
        solanaTokenService _: SolanaTokensRepository = Resolver.resolve()
    ) {
        super.init()

        /// Listen to changing in bundle
        bundle
            .$state
            .map { state in
                state.apply { bundle in
                    WormholeClaimFeeAdapter(account: account, bundle: bundle)
                }
            }
            .weakAssign(to: \.adapter, on: self)
            .store(in: &subscriptions)
    }

    func close() {
        closeAction.send()
    }
}
