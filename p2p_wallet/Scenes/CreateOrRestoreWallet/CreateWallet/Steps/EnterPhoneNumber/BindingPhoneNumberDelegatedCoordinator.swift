// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import CountriesAPI
import Foundation
import Onboarding
import SwiftUI

class BindingPhoneNumberDelegatedCoordinator: DelegatedCoordinator<BindingPhoneNumberState> {
    override func buildViewController(for state: BindingPhoneNumberState) -> UIViewController? {
        switch state {
        case let .enterPhoneNumber(initialPhoneNumber, _, _):
            let mv = EnterPhoneNumberViewModel(isBackAvailable: false)
            mv.phone = initialPhoneNumber
            let vc = EnterPhoneNumberViewController(viewModel: mv)

            mv.coordinatorIO.selectCode.sinkAsync { [weak self] code in
                guard let result = try await self?.selectCountry(selectedCountryCode: code)
                else { return }
                mv.coordinatorIO.countrySelected.send(result)
            }.store(in: &subscriptions)

            mv.coordinatorIO.phoneEntered.sinkAsync { [weak mv, stateMachine] phone in
                mv?.isLoading = true
                do {
                    try await stateMachine <- .enterPhoneNumber(phoneNumber: phone, channel: .sms)
                } catch {
                    mv?.coordinatorIO.error.send(error)
                }
                mv?.isLoading = false

            }.store(in: &subscriptions)
            return vc
        case let .enterOTP(_, _, phoneNumber, _):
            let vm = EnterSMSCodeViewModel(phone: phoneNumber)
            let vc = EnterSMSCodeViewController(viewModel: vm)

            vm.coordinatorIO.onConfirm.sinkAsync { [weak vm, stateMachine] opt in
                vm?.isLoading = true
                do {
                    try await stateMachine <- .enterOTP(opt: opt)
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

            vm.coordinatorIO.onResend.sinkAsync { [weak vm, stateMachine] in
                vm?.isLoading = true
                do {
                    try await stateMachine <- .resendOTP
                } catch {
                    vm?.coordinatorIO.error.send(error)
                }
                vm?.isLoading = false
            }.store(in: &subscriptions)

            return vc
        case let .broken(code):
            let view = OnboardingBrokenScreen(
                title: L10n.createANewWallet,
                contentData: .init(
                    image: .introWelcomeToP2pFamily,
                    title: L10n.wellWell,
                    subtitle: L10n
                        .WeVeBrokeSomethingReallyBig
                        .LetSWaitTogetherFinnalyTheAppWillBeRepaired
                        .ifYouWillWriteUsUseErrorCode("#\(abs(code))")
                ),
                back: { [stateMachine] in try await stateMachine <- .back },
                info: { /* TODO: handle */ },
                help: { /* TODO: handle */ }
            )

            return UIHostingController(rootView: view)

        case let .block(until, reason, _, _):
            var title = ""
            var contentSubtitle: (_ value: Any) -> String = { _ in "" }
            switch reason {
            case .blockEnterOTP:
                title = L10n.itSOkayToBeWrong
                contentSubtitle = L10n.YouUsed5IncorrectCodes.forYourSafetyWeFreezedAccountFor
            case .blockEnterPhoneNumber:
                title = L10n.soLetSBreathe
                contentSubtitle = L10n.YouDidnTUseAnyOf5Codes.forYourSafetyWeFreezedAccountFor
            }

            let view = OnboardingBlockScreen(
                contentTitle: title,
                contentSubtitle: contentSubtitle,
                untilTimestamp: until,
                onHome: { [stateMachine] in Task { try await stateMachine <- .home } },
                onCompletion: { [stateMachine] in Task { try await stateMachine <- .blockFinish } },
                onTermAndCondition: { [weak self] in self?.showTermAndCondition() }
            )

            return UIHostingController(rootView: view)
        default:
            return nil
        }
    }

    public func showTermAndCondition() {
        let vc = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        rootViewController?.present(vc, animated: true)
    }

    public func selectCountry(selectedCountryCode: String?) async throws -> Country? {
        guard let rootViewController = rootViewController else { return nil }
        let coordinator = ChoosePhoneCodeCoordinator(
            selectedCountryCode: selectedCountryCode,
            presentingViewController: rootViewController
        )
        return try await coordinator.start().async()
    }
}
