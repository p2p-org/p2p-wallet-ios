//
//  WormholeClaimFeeViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Wormhole

class WormholeClaimFeeViewModel: BaseViewModel, ObservableObject {
    let closeAction: PassthroughSubject<Void, Never> = .init()

    @Published var data: WormholeClaimFeeModel

    init(data: WormholeClaimFeeModel) {
        self.data = data
        super.init()
    }

    init(
        account: EthereumAccountsService.Account,
        bundle: AsyncValue<WormholeBundle?>
    ) {
        data = WormholeClaimFeeModel(account: account, bundle: bundle.state.value)

        super.init()

        /// Listen to changing in bundle
        bundle
            .$state
            .map(\.value)
            .map { WormholeClaimFeeModel(account: account, bundle: $0) }
            .weakAssign(to: \.data, on: self)
            .store(in: &subscriptions)
    }

    func close() {
        closeAction.send()
    }
}
