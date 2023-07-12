//
//  ReauthenticationSocialShareDelegatedCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import Foundation
import Onboarding
import SwiftUI

class ReAuthSocialShareDelegatedCoordinator: DelegatedCoordinator<ReAuthSocialShareState> {
    override func buildViewController(for state: ReAuthSocialShareState) -> UIViewController? {
        switch state {
        case let .signIn(socialProvider):
            let viewModel = ReAuthSocialSignInViewModel(socialProvider: socialProvider)
            let view = ReAuthSocialSignInView(viewModel: viewModel)

            let vc = UICustomHostingController(rootView: view) { vc, _ in
                vc.navigationItem.setHidesBackButton(true, animated: false)
            }

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

        case let .wrongAccount(socialProvider, wrongEmail):
            let view = ReAuthWrongAccountView(
                provider: socialProvider,
                selectedEmail: wrongEmail
            ) { [stateMachine] in
                Task {
                    try await stateMachine <- .back
                }
            } onClose: { [stateMachine] in
                Task {
                    try await stateMachine <- .cancel
                }
            }

            return UIHostingController(rootView: view)

        case .finish:
            return nil

        case .cancel:
            return nil
        }
    }
}
