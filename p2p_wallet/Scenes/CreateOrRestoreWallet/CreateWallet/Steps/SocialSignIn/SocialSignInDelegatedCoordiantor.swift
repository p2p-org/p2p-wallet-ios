// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding

class SocialSignInDelegatedCoordinator {
    typealias EventHandler = (_ event: SocialSignInEvent) async throws -> Void

    var subscriptions = [AnyCancellable]()

    let eventHandler: EventHandler
    var rootViewController: UIViewController?

    init(eventHandler: @escaping EventHandler) {
        self.eventHandler = eventHandler
    }

    func buildViewController(for state: SocialSignInState) -> UIViewController? {
        switch state {
        case .socialSelection:
            // TODO: rename class name
            let vc = SocialSignInViewController(viewModel: .init())
            vc.viewModel.coordinatorIO.onTermAndCondition.sink { [weak self] in self?.showTermAndCondition() }
                .store(in: &subscriptions)

            vc.viewModel.coordinatorIO.onBack.sinkAsync { [weak self] in
                do {
                    try await self?.eventHandler(.signInBack)
                } catch {
                    vc.viewModel.input.onError.send(error)
                }
            }.store(in: &subscriptions)

            vc.viewModel.coordinatorIO.onLogin.sinkAsync { [weak self] provider in
                if vc.viewModel.input.isLoading.value { return }
                do {
                    vc.viewModel.input.isLoading.send(true)
                    defer { vc.viewModel.input.isLoading.send(false) }

                    try await self?.eventHandler(.signIn(socialProvider: provider))
                } catch {
                    vc.viewModel.input.onError.send(error)
                }
            }.store(in: &subscriptions)
            return vc
        case let .socialSignInAccountWasUsed(provider, usedEmail):
            let vm = SocialSignInAccountHasBeenUsedViewModel(
                email: usedEmail,
                signInProvider: provider
            )

            vm.coordinatorIO.useAnotherAccount.sinkAsync { [weak self] in
                if vm.input.isLoading.value { return }
                vm.input.isLoading.send(true)
                defer { vm.input.isLoading.send(false) }

                do {
                    try await await self?.eventHandler(.signIn(socialProvider: .google))
                } catch {
                    vm.input.onError.send(error)
                }
            }

            vm.coordinatorIO.switchToRestoreFlow.sinkAsync { [weak self] in
                if vm.input.isLoading.value { return }
                vm.input.isLoading.send(true)
                defer { vm.input.isLoading.send(false) }

                do {
                    try await self?.eventHandler(.restore(authProvider: provider, email: usedEmail))
                } catch {
                    vm.input.onError.send(error)
                }
            }

            let vc = SocialSignInAccountHasBeenUsedViewController(viewModel: vm)
            return vc
        case let .socialSignInTryAgain(socialProvider, usedEmail):
            let vm = SocialSignInTryAgainViewModel(signInProvider: socialProvider)

            vm.coordinator.startScreen.sinkAsync { [weak self] in
                if vm.input.isLoading.value { return }
                vm.input.isLoading.send(true)
                defer { vm.input.isLoading.send(false) }

                do {
                    try await self?.eventHandler(.signInBack)
                } catch {
                    vm.input.onError.send(error)
                }
            }.store(in: &subscriptions)

            vm.coordinator.tryAgain.sinkAsync { [weak self] in
                vm.input.isLoading.send(true)
                defer { vm.input.isLoading.send(false) }

                do {
                    try await self?.eventHandler(.signIn(socialProvider: socialProvider))
                } catch {
                    vm.input.onError.send(error)
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
