// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import CountriesAPI
import Foundation
import Onboarding
import Resolver
import SwiftUI
import AnalyticsManager

class BindingPhoneNumberDelegatedCoordinator: DelegatedCoordinator<BindingPhoneNumberState> {
    @Injected private var helpLauncher: HelpCenterLauncher
    @Injected private var analyticsManager: AnalyticsManager

    override func buildViewController(for state: BindingPhoneNumberState) -> UIViewController? {
        switch state {
        case let .enterPhoneNumber(initialPhoneNumber, _, _, _):
            analyticsManager.log(event: AmplitudeEvent.creationPhoneScreen)

            let mv = EnterPhoneNumberViewModel(
                phone: initialPhoneNumber,
                isBackAvailable: false,
                strategy: .create
            )
            let vc = EnterPhoneNumberViewController(viewModel: mv)
            vc.title = L10n.stepOf("2", "3")

            mv.coordinatorIO.selectCode.sinkAsync { [weak self] dialCode, countryCode in
                guard let result = try await self?.selectCountry(
                    selectedDialCode: dialCode,
                    selectedCountryCode: countryCode
                )
                else { return }
                mv.coordinatorIO.countrySelected.send(result)
            }.store(in: &subscriptions)

            mv.coordinatorIO.helpClicked
                .sink(receiveValue: { [unowned self] in
                    openHelp()
                })
                .store(in: &subscriptions)

            mv.coordinatorIO.phoneEntered.sinkAsync { [weak mv, stateMachine] phone in
                mv?.isLoading = true
                do {
                    try await stateMachine <- .enterPhoneNumber(phoneNumber: phone, channel: .sms)
                } catch APIGatewayError.changePhone {
                    vc.showError(error: L10n.SMSWillNotBeDelivered.pleaseChangePhoneNumber)
                } catch {
                    mv?.coordinatorIO.error.send(error)
                }
                mv?.isLoading = false

            }.store(in: &subscriptions)
            return vc
        case let .enterOTP(resendCounter, _, phoneNumber, _):
            let vm = EnterSMSCodeViewModel(
                phone: phoneNumber,
                attemptCounter: resendCounter,
                strategy: .create
            )
            let vc = EnterSMSCodeViewController(viewModel: vm)
            vc.title = L10n.stepOf("2", "3")

            vm.coordinatorIO.onConfirm.sinkAsync { [weak vm, stateMachine] opt in
                vm?.isLoading = true
                do {
                    try await stateMachine <- .enterOTP(opt: opt)
                } catch {
                    vm?.coordinatorIO.error.send(error)
                }
                vm?.isLoading = false
            }.store(in: &subscriptions)

            vm.coordinatorIO.showInfo
                .sink(receiveValue: { [unowned self] in
                    openHelp()
                })
                .store(in: &subscriptions)

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

            return vc
        case let .broken(code):
            let view = OnboardingBrokenScreen(
                title: L10n.createANewWallet,
                contentData: .init(
                    image: .womanNotFound,
                    title: L10n.wellWell,
                    subtitle: L10n
                        .WeVeBrokeSomethingReallyBig
                        .LetSWaitTogetherFinallyTheAppWillBeRepaired
                        .ifYouWishToReportTheIssueUseErrorCode(abs(code))
                ),
                back: { [stateMachine] in try await stateMachine <- .back },
                info: { [unowned self] in
                    openHelp()
                },
                help: { [unowned self] in
                    openHelp()
                }
            )

            return UIHostingController(rootView: view)

        case let .block(until, reason, _, _):
            var title = ""
            var contentSubtitle: (_ value: Any) -> String = { _ in "" }
            switch reason {
            case .blockEnterOTP:
                title = L10n.itSOkayToBeWrong
                contentSubtitle = L10n.YouUsed5IncorrectCodes.forYourSafetyWeHaveFrozenYourAccountFor
            case .blockEnterPhoneNumber:
                title = L10n.itSOkayToBeWrong
                contentSubtitle = L10n.YouUsedTooMuchNumbers.forYourSafetyWeHaveFrozenYourAccountFor
            case .blockResend:
                title = L10n.soLetSBreathe
                contentSubtitle = L10n.YouDidnTUseAnyOf5Codes.forYourSafetyWeHaveFrozenYourAccountFor
            }

            let view = OnboardingBlockScreen(
                contentTitle: title,
                contentSubtitle: contentSubtitle,
                untilTimestamp: until,
                onHome: { [stateMachine] in Task { try await stateMachine <- .home } },
                onCompletion: { [stateMachine] in Task { try await stateMachine <- .blockFinish } },
                onTermsOfService: { [weak self] in self?.openTermsOfService() },
                onPrivacyPolicy: { [weak self] in self?.openPrivacyPolicy() },
                onInfo: { [weak self] in self?.openHelp() }
            )

            return UIHostingController(rootView: view)
        default:
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

    public func selectCountry(selectedDialCode: String?, selectedCountryCode: String?) async throws -> Country? {
        guard let rootViewController = rootViewController else { return nil }
        let coordinator = ChoosePhoneCodeCoordinator(
            selectedDialCode: selectedDialCode,
            selectedCountryCode: selectedCountryCode,
            presentingViewController: rootViewController
        )
        return try await coordinator.start().async()
    }

    private func openHelp() {
        helpLauncher.launch()
    }
}
