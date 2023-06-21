//
//  ReauthenticationWithoutDeviceShareViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import Combine
import Foundation
import Onboarding
import Resolver

final class ReAuthWithoutDeviceShareViewModel: BaseViewModel, ObservableObject {
    let facade: TKeyFacade
    let stateMachine: StateMachine<ReAuthWithoutDeviceShareState>

    init(facade: TKeyFacade, metadata: WalletMetaData) {
        self.facade = facade
        let userWalletManager: UserWalletManager = Resolver.resolve()

        stateMachine = .init(
            initialState: .customShare(
                .otpInput(
                    phoneNumber: metadata.phoneNumber,
                    solPrivateKey: userWalletManager.wallet!.account.secretKey,
                    resendCounter: .init(.zero())
                )
            ),
            provider: .init(
                apiGateway: Resolver.resolve(),
                facade: facade,
                socialAuthService: Resolver.resolve(),
                walletMetadata: metadata
            )
        )
    }
}
