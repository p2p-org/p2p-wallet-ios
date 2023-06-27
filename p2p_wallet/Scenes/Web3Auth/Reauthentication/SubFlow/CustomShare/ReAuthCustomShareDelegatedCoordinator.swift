//
//  CustomShareDelegatedCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import Foundation
import Onboarding
import Resolver
import SwiftUI

class ReAuthCustomShareDelegatedCoordinator: DelegatedCoordinator<ReAuthCustomShareState> {
    override func buildViewController(for state: ReAuthCustomShareState) -> UIViewController? {
        switch state {
        case let .otpInput(phoneNumber, _, resendCounter):
            let vm = EnterSMSCodeViewModel(
                phone: phoneNumber,
                attemptCounter: resendCounter,
                strategy: .create
            )
            let vc = EnterSMSCodeViewController(viewModel: vm, disableRightButton: true)
            vc.title = L10n.confirmYourNumber

            vm.coordinatorIO.onConfirm.sinkAsync { [weak vm, stateMachine] opt in
                vm?.isLoading = true
                do {
                    try await stateMachine <- .enterOTP(opt)
                } catch {
                    vm?.coordinatorIO.error.send(error)
                }
                vm?.isLoading = false
            }.store(in: &subscriptions)

            vm.coordinatorIO.goBack.sinkAsync { [weak vm, stateMachine] in
                vm?.isLoading = true
                do {
                    try await stateMachine <- .back
                } catch {
                    vm?.coordinatorIO.error.send(error)
                }
                vm?.isLoading = false
            }.store(in: &subscriptions)

            vm.coordinatorIO.onResend.sinkAsync { [stateMachine] process in
                process.start { try await stateMachine <- .resendOTP }
            }.store(in: &subscriptions)

            vm.coordinatorIO.onStart.sinkAsync { [stateMachine] process in
                process.start { try await stateMachine <- .start }
            }.store(in: &subscriptions)

            return vc

        case let .block(until, phoneNumber, solPrivateKey):
            let title = L10n.confirmationCodeLimitHit
            let contentSubtitle: (_ value: Any) -> String = L10n.YouVeUsedAll5Codes.TryAgainIn.forHelpContactSupport

            let view = OnboardingBlockScreen(
                primaryButtonAction: L10n.back,
                contentTitle: title,
                contentSubtitle: contentSubtitle,
                untilTimestamp: until,
                onHome: { [stateMachine] in Task { try await stateMachine <- .back } },
                onCompletion: { [stateMachine] in Task { try await stateMachine <- .blockValidate } },
                onTermsOfService: { [weak self] in self?.openTermsOfService() },
                onPrivacyPolicy: { [weak self] in self?.openPrivacyPolicy() },
                onInfo: { [weak self] in self?.openHelp() }
            )

            return UIHostingController(rootView: view)

        case .finish:
            return nil

        case .cancel:
            return nil
        }
    }

    public func openTermsOfService() {
        let vc = WLMarkdownVC(
            title: L10n.termsOfService,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        rootViewController?.present(vc, animated: true)
    }

    private func openPrivacyPolicy() {
        let viewController = WLMarkdownVC(
            title: L10n.privacyPolicy,
            bundledMarkdownTxtFileName: "Privacy_policy"
        )
        rootViewController?.present(viewController, animated: true)
    }

    private func openHelp() {
        let helpLauncher: HelpCenterLauncher = Resolver.resolve()
        helpLauncher.launch()
    }
}
