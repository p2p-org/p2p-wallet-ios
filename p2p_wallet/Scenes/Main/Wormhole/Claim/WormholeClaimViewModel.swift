//
//  WormholeClaimViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver

class WormholeClaimViewModel: BaseViewModel, ObservableObject {
    let action: PassthroughSubject<Action, Never> = .init()

    @Published var model: any WormholeClaimModel

    init(model: WormholeClaimMockModel) {
        self.model = model
        super.init()
    }

    init(
        account: EthereumAccountsService.Account,
        ethereumAccountsService: EthereumAccountsService = Resolver.resolve()
    ) {
        self.model = WormholeClaimEthereumModel(account: account)

        super.init()
    }

    func claim() {
        if let model = model as? WormholeClaimEthereumModel {
            action.send(
                .claiming(
                    PendingTransaction(
                        trxIndex: 0,
                        sentAt: Date(),
                        rawTransaction: WormholeClaimTransaction(
                            token: model.account.token,
                            amountInCrypto: model.account.representedBalance,
                            amountInFiat: model.account.balanceInFiat
                        ),
                        status: .sending
                    )
                )
            )
        }
    }
}

extension WormholeClaimViewModel {
    enum Action {
        case openFee
        case claiming(PendingTransaction)
    }
}
