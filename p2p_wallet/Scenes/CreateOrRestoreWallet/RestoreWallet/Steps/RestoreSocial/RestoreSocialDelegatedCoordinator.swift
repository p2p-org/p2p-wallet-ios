// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Onboarding
import Resolver
import SwiftUI

final class RestoreSocialDelegatedCoordinator: DelegatedCoordinator<RestoreSocialState> {
    @Injected private var helpLauncher: HelpCenterLauncher

    override func buildViewController(for state: RestoreSocialState) -> UIViewController? {
        switch state {
        case .signIn:
            return nil
        case .social:
            return handleSocial()
        case let .notFoundCustom(_, email):
            return handleNotFoundCustom(email: email)
        case let .notFoundDevice(data, _, _):
            let subtitles: [OnboardingContentData.Subtitle] = [
                .init(text: L10n.ifYouWantToContinueWith),
                .init(text: data.email, isLimited: true),
                .init(text: L10n.SelectPhoneNumber.ifYouMadeAMistakePleaseChooseAnotherMail),
            ]
            return handleNotFoundDeviceSocial(title: L10n.almostDone, subtitles: subtitles)
        case let .notFoundSocial(data, _, _):
            let subtitles: [OnboardingContentData.Subtitle] = [
                .init(text: data.email, isLimited: true),
                .init(text: L10n.tryAnotherAccountOrUseAPhoneNumber),
            ]
            return handleNotFoundDeviceSocial(title: L10n.notFound, subtitles: subtitles)
        case .expiredSocialTryAgain:
            return nil
        case .finish:
            return nil
        }
    }

    private func openInfo() {
        helpLauncher.launch()
    }

    private func socialSignInParameters() -> SocialSignInParameters {
        let content = OnboardingContentData(image: .easyToStart, title: L10n.howToContinue)
        let parameters = SocialSignInParameters(
            title: L10n.restoreYourWallet,
            content: content,
            appleButtonTitle: L10n.continueWithApple,
            googleButtonTitle: L10n.continueWithGoogle,
            isBackAvailable: false
        )
        return parameters
    }
}

private extension RestoreSocialDelegatedCoordinator {
    func handleSocial() -> UIViewController {
        let viewModel = SocialSignInViewModel(parameters: socialSignInParameters())
        let view = SocialSignInView(viewModel: viewModel)
        viewModel.outInfo.sink { [weak self] in self?.openInfo() }
            .store(in: &subscriptions)

        viewModel.outLogin.sinkAsync { [stateMachine] process in
            process.start {
                _ = try await stateMachine <- .signInCustom(socialProvider: process.data)
            }
        }
        .store(in: &subscriptions)

        return UIHostingController(rootView: view)
    }

    func handleNotFoundDeviceSocial(title: String, subtitles: [OnboardingContentData.Subtitle]) -> UIViewController {
        let parameters = ChooseRestoreOptionParameters(
            isBackAvailable: false,
            content: OnboardingContentData(image: .catFail, title: title, subtitles: subtitles),
            options: [.socialApple, .socialGoogle, .custom],
            isStartAvailable: true
        )
        let chooseRestoreOptionViewModel = ChooseRestoreOptionViewModel(parameters: parameters)
        chooseRestoreOptionViewModel.optionChosen.sinkAsync(receiveValue: { [stateMachine] process in
            process.start {
                switch process.data {
                case .custom:
                    _ = try await stateMachine <- .requireCustom
                case .socialApple:
                    _ = try await stateMachine <- .signInDevice(socialProvider: .apple)
                case .socialGoogle:
                    _ = try await stateMachine <- .signInDevice(socialProvider: .google)
                default: break
                }
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
            image: .catFail,
            title: L10n.noWalletFound,
            subtitles: [
                OnboardingContentData.Subtitle(text: email, isLimited: true),
                OnboardingContentData.Subtitle(text: L10n.tryAnotherOption),
            ]
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
