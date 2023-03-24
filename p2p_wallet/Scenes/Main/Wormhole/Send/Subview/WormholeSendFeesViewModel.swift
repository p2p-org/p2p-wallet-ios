//
//  WormholeSendFeesViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Send

struct WormholeSendFees: Identifiable {
    var id: String { title }

    let title: String

    let subtitle: String

    let detail: String

    init?(title: String, subtitle: String?, detail: String?) {
        guard let subtitle else {
            return nil
        }

        self.title = title
        self.subtitle = subtitle
        self.detail = detail ?? ""
    }
}

class WormholeSendFeesViewModel: BaseViewModel, ObservableObject {
    @Published var loading: Bool = false
    @Published var fees: [WormholeSendFees] = []

    init(fees: [WormholeSendFees]) {
        self.fees = fees
    }

    init(
        stateMachine: WormholeSendInputStateMachine,
        ethereumTokensRepository: EthereumTokensRepository = Resolver.resolve(),
        solanaTokensRepository: SolanaTokensService = Resolver.resolve()
    ) {
        super.init()

        stateMachine
            .state
            .sink { [weak self] state in

                Task {
                    let adapter = await WormholeSendFeesAdapter(
                        adapter: WormholeSendInputStateAdapter(state: state),
                        ethereumTokensRepository: ethereumTokensRepository,
                        solanaTokensRepository: solanaTokensRepository
                    )

                    DispatchQueue.main.async { [weak self] in
                        self?.fees = [
                            .init(title: L10n.recipientSAddress, subtitle: adapter.recipientAddress, detail: ""),
                            .init(title: L10n.recipientGets, subtitle: adapter.receive.crypto, detail: adapter.receive.fiat),
                            .init(title: L10n.networkFee, subtitle: adapter.networkFee?.crypto, detail: adapter.networkFee?.fiat),
                            .init(title: L10n.usingWormholeBridge, subtitle: adapter.bridgeFee?.crypto, detail: adapter.bridgeFee?.fiat),
                        ].compactMap { $0 }
                    }
                }
            }
            .store(in: &subscriptions)
    }
}
