// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding

class SocialSignInDelegatedCoordinator: DelegatedCoordinator<SocialSignInState> {
    override func buildViewController(for state: SocialSignInState) -> UIViewController? {
        switch state {
        case .socialSelection:
            // TODO: rename class name
            let vm = SocialSignInViewModel()
            let vc = SocialSignInViewController(viewModel: vm)
            vc.viewModel.coordinatorIO.onTermAndCondition.sink { [weak self] in self?.showTermAndCondition() }
                .store(in: &subscriptions)

            vc.viewModel.coordinatorIO.onBack.sinkAsync { [weak vm, stateMachine] in
                vm?.input.isLoading.send(true)
                do {
                    try await stateMachine <- .signInBack
                } catch {
                    vc.viewModel.input.onError.send(error)
                }
                vm?.input.isLoading.send(false)
            }.store(in: &subscriptions)

            vc.viewModel.coordinatorIO.onLogin.sinkAsync { [weak vm, stateMachine] provider in
                if vc.viewModel.input.isLoading.value { return }
                vm?.input.isLoading.send(true)
                do {
                    try await stateMachine <- .signIn(socialProvider: provider)
                } catch {
                    defer { vm?.input.isLoading.send(false) }
                    if case SocialServiceError.cancelled = error {
                        // Not sending error if it's cancelled byy user
                        return
                    }
                    vc.viewModel.input.onError.send(error)
                }
            }.store(in: &subscriptions)
            return vc
        case let .socialSignInAccountWasUsed(provider, usedEmail):
            let vm = SocialSignInAccountHasBeenUsedViewModel(
                email: usedEmail,
                signInProvider: provider
            )

            vm.coordinatorIO.useAnotherAccount.sinkAsync { [weak vm, stateMachine] in
                if vm?.input.isLoading.value ?? false { return }
                vm?.input.isLoading.send(true)
                defer { vm?.input.isLoading.send(false) }

                do {
                    try await stateMachine <- .signIn(socialProvider: .google)
                } catch {
                    vm?.input.onError.send(error)
                }
            }

            vm.coordinatorIO.switchToRestoreFlow.sinkAsync { [weak vm, stateMachine] in
                if vm?.input.isLoading.value ?? false { return }
                vm?.input.isLoading.send(true)
                defer { vm?.input.isLoading.send(false) }

                do {
                    try await stateMachine <- .restore(authProvider: provider, email: usedEmail)
                } catch {
                    vm?.input.onError.send(error)
                }
            }

            let vc = SocialSignInAccountHasBeenUsedViewController(viewModel: vm)
            return vc
        case let .socialSignInTryAgain(socialProvider, usedEmail):
            let vm = SocialSignInTryAgainViewModel(signInProvider: socialProvider)

            vm.coordinator.startScreen.sinkAsync { [weak vm, stateMachine] in
                if vm?.input.isLoading.value ?? false { return }
                vm?.input.isLoading.send(true)
                defer { vm?.input.isLoading.send(false) }

                do {
                    try await stateMachine <- .signInBack
                } catch {
                    vm?.input.onError.send(error)
                }
            }.store(in: &subscriptions)

            vm.coordinator.tryAgain.sinkAsync { [weak vm, stateMachine] in
                vm?.input.isLoading.send(true)
                defer { vm?.input.isLoading.send(false) }

                do {
                    try await stateMachine <- .signIn(socialProvider: socialProvider)
                } catch {
                    vm?.input.onError.send(error)
                }
            }.store(in: &subscriptions)

            let vc = SocialSignInTryAgainViewController(viewModel: vm)
            return vc
        default: return nil
        }
    }

    public func showTermAndCondition() {
        let vc = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        rootViewController?.present(vc, animated: true)
    }
}
