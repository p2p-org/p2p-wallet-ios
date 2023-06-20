//
//  ReauthenticationSocialShareDelegatedCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import Foundation
import Onboarding
import SwiftUI

class ReAuthSocialShareDelegatedCoordinator: DelegatedCoordinator<ReauthenticationSocialShareState> {
    override func buildViewController(for state: ReauthenticationSocialShareState) -> UIViewController? {
        switch state {
        case let .signIn(socialProvider):
            let viewModel = ReAuthSocialSignInViewModel(socialProvider: socialProvider)
            let view = ReAuthSocialSignInView(viewModel: viewModel)
            let vc = UIHostingController(rootView: view)

            viewModel.onClose.sink { [stateMachine] in
                Task {
                    try await stateMachine <- .cancel
                }
            }.store(in: &subscriptions)

            viewModel.onContinue.sinkAsync { [stateMachine] process in
                process.start {
                    try await stateMachine <- .signIn
                }
            }.store(in: &subscriptions)

            return vc

        case .finish:
            return nil

        case .cancel:
            return nil
        }
    }
}
