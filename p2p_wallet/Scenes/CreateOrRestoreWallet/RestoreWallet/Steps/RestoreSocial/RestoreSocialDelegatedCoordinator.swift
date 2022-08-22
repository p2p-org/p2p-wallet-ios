// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Onboarding
import SwiftUI

final class RestoreSocialDelegatedCoordinator: DelegatedCoordinator<RestoreSocialState> {
    override func buildViewController(for state: RestoreSocialState) -> UIViewController? {
        switch state {
        case .signIn:
            return nil
        case .social:
            let viewModel = SocialSignInViewModel(title: L10n.restoringYourWallet)
            let view = SocialSignInView(viewModel: viewModel)
            viewModel.coordinatorIO.outTermAndCondition.sink { [weak self] in self?.openTerms() }
                .store(in: &subscriptions)

            viewModel.coordinatorIO.outBack.sinkAsync { _ in
                // is back necessary here? waiting for design
            }
            .store(in: &subscriptions)

            viewModel.coordinatorIO.outLogin.sinkAsync { [stateMachine] process in
                process
                    .start {
                        _ = try await stateMachine <- .signInCustom(socialProvider: process.data)
                    }
            }
            .store(in: &subscriptions)

            return UIHostingController(rootView: view)
        case .finish:
            return nil
        }
    }

    public func openTerms() {
        let viewController = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        rootViewController?.present(viewController, animated: true)
    }
}
