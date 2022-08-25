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
            let viewModel = SocialSignInViewModel(parameters: socialSignInParameters())
            let view = SocialSignInView(viewModel: viewModel)
            viewModel.coordinatorIO.outTermAndCondition.sink { [weak self] in self?.openTerms() }
                .store(in: &subscriptions)

            viewModel.coordinatorIO.outBack.sinkAsync { [stateMachine] process in
                process.start { _ = try await stateMachine <- .back }
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

    private func socialSignInParameters() -> SocialSignInParameters {
        let content = OnboardingContentData(image: .safeRestore, title: L10n.howToContinue)
        let parameters = SocialSignInParameters(
            title: L10n.restoringYourWallet,
            content: content,
            appleButtonTitle: L10n.continueWithApple,
            googleButtonTitle: L10n.continueWithGoogle
        )
        return parameters
    }
}
