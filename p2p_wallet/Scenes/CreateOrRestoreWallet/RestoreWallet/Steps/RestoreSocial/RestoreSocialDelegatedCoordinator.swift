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
            return handleSocial()
        case let .notFoundCustom(_, email):
            return handleNotFoundCustom(email: email)
        case let .notFoundDevice(data, code, _):
            return handleNotFoundDevice(email: code == 1009 ? data.email : nil)
        case .expiredSocialTryAgain:
            return nil
        case .finish:
            return nil
        }
    }

    private func openTerms() {
        let viewController = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        rootViewController?.present(viewController, animated: true)
    }

    private func openInfo() {
        openTerms()
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

private extension RestoreSocialDelegatedCoordinator {
    func handleSocial() -> UIViewController {
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
    }

    func handleNotFoundDevice(email: String?) -> UIViewController {
        let subtitle = email == nil ? L10n.tryWithAnotherAccountOrUseAPhoneNumber : L10n
            .emailTryAnotherAccountOrUseAPhoneNumber(email ?? "")
        let parameters = ChooseRestoreOptionParameters(
            isBackAvailable: false,
            content: OnboardingContentData(image: .box, title: L10n.notFound, subtitle: subtitle),
            options: [.socialApple, .socialGoogle, .custom],
            isStartAvailable: true
        )
        let chooseRestoreOptionViewModel = ChooseRestoreOptionViewModel(parameters: parameters)
        chooseRestoreOptionViewModel.optionChosen.sinkAsync(receiveValue: { [stateMachine] process in
            switch process.data {
            case .custom:
                _ = try await stateMachine <- .requireCustom
            case .socialApple:
                _ = try await stateMachine <- .signInDevice(socialProvider: .apple)
            case .socialGoogle:
                _ = try await stateMachine <- .signInDevice(socialProvider: .google)
            default: break
            }
        })
            .store(in: &subscriptions)
        chooseRestoreOptionViewModel.openStart.sinkAsync { [stateMachine] in
            _ = try await stateMachine <- .start
        }
        .store(in: &subscriptions)
        chooseRestoreOptionViewModel.openInfo.sink { [weak self] in
            self?.openInfo()
        }
        .store(in: &subscriptions)
        chooseRestoreOptionViewModel.back.sinkAsync { [stateMachine] in
            _ = try await stateMachine <- .back
        }
        .store(in: &subscriptions)
        return UIHostingController(rootView: ChooseRestoreOptionView(viewModel: chooseRestoreOptionViewModel))
    }

    func handleNotFoundCustom(email: String) -> UIViewController {
        let content = OnboardingContentData(
            image: .box,
            title: L10n.noWalletFound,
            subtitle: L10n.withTryAnotherAccount(email)
        )
        let actionViewModel = RestoreSocialOptionViewModel()
        actionViewModel.optionChosen.sinkAsync { [stateMachine] process in
            process.start {
                _ = try await stateMachine <- .signInCustom(socialProvider: process.data)
            }
        }.store(in: &subscriptions)
        let actionView = RestoreSocialOptionView(viewModel: actionViewModel)
        let view = OnboardingBrokenScreen(title: "", contentData: content, back: { [stateMachine] in
            Task { _ = try await stateMachine <- .start }
        }, info: { [weak self] in
            self?.openInfo()
        }, customActions: { actionView })
        return UIHostingController(rootView: view)
    }
}
