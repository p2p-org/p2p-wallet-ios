// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import CountriesAPI
import KeyAppUI
import Onboarding
import Resolver
import SwiftUI

final class RestoreCustomDelegatedCoordinator: DelegatedCoordinator<RestoreCustomState> {
    @Injected private var helpLauncher: HelpCenterLauncher

    override func buildViewController(for state: RestoreCustomState) -> UIViewController? {
        switch state {
        case let .enterPhone(initialPhoneNumber, _, _, _, _):
            return handleEnterPhone(phone: initialPhoneNumber)

        case let .enterOTP(phone, _, _, resendCounter):
            return handleEnterOtp(phone: phone, resendCounter: resendCounter)

        case let .otpNotDeliveredTrySocial(phone, code):
            return handleOtpNotDeliveredRequireSocial(phone: phone, code: code)

        case let .otpNotDelivered(phone, code):
            return handleOtpNotDelivered(phone: phone, code: code)

        case .noMatch:
            return handleNoMatch()

        case let .broken(code):
            return handleBroken(code: code)

        case let .tryAnother(wrongNumber, trySocial):
            return tryAnother(wrongNumber: wrongNumber, trySocial: trySocial)

        case let .block(until, _, reason):
            return handleBlock(until: until, reason: reason)

        case .expiredSocialTryAgain:
            return handleExpiredSocialTryAgain()

        case .notFoundDevice:
            return handleNotFound()

        default:
            return nil
        }
    }

    private func openHelp() {
        helpLauncher.launch()
    }

    private func openTermAndCondition() {
        let viewController = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        rootViewController?.present(viewController, animated: true)
    }

    private func selectCountry(selectedDialCode: String?, selectedCountryCode: String?) async throws -> Country? {
        guard let rootViewController = rootViewController else { return nil }
        let coordinator = ChoosePhoneCodeCoordinator(
            selectedDialCode: selectedDialCode,
            selectedCountryCode: selectedCountryCode,
            presentingViewController: rootViewController
        )
        return try await coordinator.start().async()
    }

    private func weCanTSMSYouContent(phone: String, code: Int) -> OnboardingContentData {
        OnboardingContentData(
            image: .catFail,
            title: L10n.weCanTSMSYou,
            subtitle: L10n
                .SomethingWrongWithPhoneNumberOrSettings
                .ifYouWishToReportTheIssueUseErrorCode(phone, abs(code))
        )
    }
}

// MARK: - Single state handlers

private extension RestoreCustomDelegatedCoordinator {
    func handleEnterPhone(phone: String?) -> UIViewController {
        let viewModel = EnterPhoneNumberViewModel(phone: phone, isBackAvailable: true)
        viewModel.subtitle = L10n.addAPhoneNumberToRestoreYourAccount
        let viewController = EnterPhoneNumberViewController(viewModel: viewModel)

        viewModel.coordinatorIO.selectCode.sinkAsync { [weak self] dialCode, countryCode in
            guard let result = try await self?.selectCountry(
                selectedDialCode: dialCode,
                selectedCountryCode: countryCode
            ) else { return }
            viewModel.coordinatorIO.countrySelected.send(result)
        }.store(in: &subscriptions)

        viewModel.coordinatorIO.phoneEntered.sinkAsync { [weak viewModel, stateMachine] phone in
            viewModel?.isLoading = true

            do {
                _ = try await stateMachine <- .enterPhoneNumber(phone: phone)
            } catch {
                viewModel?.coordinatorIO.error.send(error)
            }
            viewModel?.isLoading = false

        }.store(in: &subscriptions)

        viewModel.coordinatorIO.helpClicked
            .sink(receiveValue: { [unowned self] in
                openHelp()
            })
            .store(in: &subscriptions)

        viewModel.coordinatorIO.back.sinkAsync { [stateMachine] in
            _ = try await stateMachine <- .back
        }.store(in: &subscriptions)

        return viewController
    }

    func handleEnterOtp(phone: String, resendCounter: Wrapper<ResendCounter>) -> UIViewController {
        let viewModel = EnterSMSCodeViewModel(phone: phone, attemptCounter: resendCounter)
        let viewController = EnterSMSCodeViewController(viewModel: viewModel)

        viewModel.coordinatorIO.onConfirm.sinkAsync { [weak viewModel, stateMachine] otp in
            viewModel?.isLoading = true
            do {
                try await stateMachine <- .enterOTP(otp: otp)
            } catch {
                viewModel?.coordinatorIO.error.send(error)
            }
            viewModel?.isLoading = false
        }.store(in: &subscriptions)

        viewModel.coordinatorIO.showInfo
            .sink(receiveValue: { [unowned self] in
                openHelp()
            })
            .store(in: &subscriptions)

        viewModel.coordinatorIO.goBack.sinkAsync { [weak viewModel, stateMachine] in
            viewModel?.isLoading = true
            do {
                try await stateMachine <- .back
            } catch {
                viewModel?.coordinatorIO.error.send(error)
            }
            viewModel?.isLoading = false
        }.store(in: &subscriptions)

        viewModel.coordinatorIO.onResend.sinkAsync { [stateMachine] process in
            process.start { try await stateMachine <- .resendOTP }
        }.store(in: &subscriptions)

        return viewController
    }

    func handleOtpNotDeliveredRequireSocial(phone: String, code: Int) -> UIViewController {
        let parameters = ChooseRestoreOptionParameters(
            isBackAvailable: true,
            content: weCanTSMSYouContent(phone: phone, code: code),
            options: [.socialApple, .socialGoogle],
            isStartAvailable: true
        )

        let viewModel = ChooseRestoreOptionViewModel(parameters: parameters)
        viewModel.optionChosen.sinkAsync(receiveValue: { [stateMachine] process in
            process.start {
                switch process.data {
                case .socialApple:
                    _ = try await stateMachine <- .requireSocial(provider: .apple)
                case .socialGoogle:
                    _ = try await stateMachine <- .requireSocial(provider: .google)
                default: break
                }
            }
        })
            .store(in: &subscriptions)

        viewModel.openStart.sinkAsync { [stateMachine] in
            _ = try await stateMachine <- .start
        }
        .store(in: &subscriptions)
        viewModel.openInfo.sink { [weak self] in
            self?.openHelp()
        }
        .store(in: &subscriptions)
        viewModel.back.sinkAsync { [stateMachine] in
            _ = try await stateMachine <- .back
        }
        .store(in: &subscriptions)

        return UIHostingController(rootView: ChooseRestoreOptionView(viewModel: viewModel))
    }

    func handleOtpNotDelivered(phone: String, code: Int) -> UIViewController {
        let content = weCanTSMSYouContent(phone: phone, code: code)
        return buildOnboardingBrokenScreen(content: content)
    }

    func handleNoMatch() -> UIViewController {
        let content = OnboardingContentData(
            image: .catFail,
            title: L10n.noWalletFound,
            subtitle: L10n.tryWithAnotherAccount
        )
        return buildOnboardingBrokenScreen(content: content)
    }

    func handleBroken(code: Int) -> UIViewController {
        let content = OnboardingContentData(
            image: .womanNotFound,
            title: L10n.wellWell,
            subtitle: L10n.YouVeFindASeldonPage🦄ItSLikeAUnicornButItSACrush.WeReAlreadyFixingIt
                .ifYouWishToReportTheIssueUseErrorCode(code)
        )
        return buildOnboardingBrokenScreen(content: content)
    }

    func buildOnboardingBrokenScreen(content: OnboardingContentData) -> UIViewController {
        let view = OnboardingBrokenScreen(title: "", contentData: content, back: { [stateMachine] in
            Task { _ = try await stateMachine <- .start }
        }, info: { [weak self] in
            self?.openHelp()
        }, help: { [weak self] in
            self?.openHelp()
        })
        return UIHostingController(rootView: view)
    }

    func tryAnother(wrongNumber: String, trySocial: Bool) -> UIViewController {
        if trySocial {
            let content = OnboardingContentData(
                image: .catFail,
                title: L10n.noWalletFound,
                subtitle: L10n.tryWithAnotherAccountOrUseAPhoneNumber
            )
            let parameters = ChooseRestoreOptionParameters(
                isBackAvailable: false,
                content: content,
                options: [.socialApple, .socialGoogle, .custom],
                isStartAvailable: true
            )

            let viewModel = ChooseRestoreOptionViewModel(parameters: parameters)
            viewModel.optionChosen.sinkAsync(receiveValue: { [stateMachine] process in
                process.start {
                    switch process.data {
                    case .socialApple:
                        _ = try await stateMachine <- .requireSocial(provider: .apple)
                    case .socialGoogle:
                        _ = try await stateMachine <- .requireSocial(provider: .google)
                    case .custom:
                        _ = try await stateMachine <- .enterPhone
                    default: break
                    }
                }
            })
                .store(in: &subscriptions)

            viewModel.openStart.sinkAsync { [stateMachine] in
                _ = try await stateMachine <- .start
            }
            .store(in: &subscriptions)
            viewModel.openInfo.sink { [weak self] in
                self?.openHelp()
            }
            .store(in: &subscriptions)

            return UIHostingController(rootView: ChooseRestoreOptionView(viewModel: viewModel))
        } else {
            let content = OnboardingContentData(
                image: .catFail,
                title: L10n.accountNotFound,
                subtitle: L10n.DoesnTWork.tryAnotherOption(wrongNumber)
            )
            let view = OnboardingBrokenScreen(title: "", contentData: content, back: { [stateMachine] in
                Task { _ = try await stateMachine <- .start }
            }, info: { [weak self] in
                self?.openHelp()
            }, help: nil,
            customActions: {
                TextButtonView(title: L10n.useAnAnotherPhone, style: .inverted,
                               size: .large) { [stateMachine] in
                    Task { _ = try await stateMachine <- .enterPhone }
                }.frame(height: TextButton.Size.large.height).frame(maxWidth: .infinity)
            })
            return UIHostingController(rootView: view)
        }
    }

    func handleBlock(until: Date, reason: PhoneFlowBlockReason) -> UIViewController {
        let subtitle: (_ value: Any) -> String
        switch reason {
        case .blockEnterOTP:
            subtitle = L10n.YouUsed5IncorrectCodes.forYourSafetyWeHaveFrozenYourAccountFor
        case .blockEnterPhoneNumber:
            subtitle = L10n.YouUsedTooMuchNumbers.forYourSafetyWeHaveFrozenYourAccountFor
        case .blockResend:
            subtitle = L10n.YouDidnTUseAnyOf5Codes.forYourSafetyWeHaveFrozenYourAccountFor
        }
        let view = OnboardingBlockScreen(
            contentTitle: L10n.soLetSBreathe,
            contentSubtitle: subtitle,
            untilTimestamp: until,
            onHome: { [stateMachine] in Task { _ = try await stateMachine <- .start } },
            onCompletion: { [stateMachine] in
                Task { _ = try await stateMachine <- .enterPhone }
            },
            onTermAndCondition: { [weak self] in self?.openTermAndCondition() },
            onInfo: { [weak self] in self?.openHelp() }
        )
        return UIHostingController(rootView: view)
    }

    func handleExpiredSocialTryAgain() -> UIViewController {
        let content = OnboardingContentData(
            image: .catFail,
            title: L10n.noWalletFound,
            subtitle: L10n.repeatSocialAuth
        )
        let actionViewModel = RestoreSocialOptionViewModel()
        actionViewModel.optionChosen.sinkAsync { [stateMachine] process in
            process.start {
                _ = try await stateMachine <- .requireSocial(provider: process.data)
            }
        }.store(in: &subscriptions)
        let actionView = RestoreSocialOptionView(viewModel: actionViewModel)
        let view = OnboardingBrokenScreen(title: "", contentData: content, back: { [stateMachine] in
            Task { _ = try await stateMachine <- .start }
        }, info: { [weak self] in
            self?.openHelp()
        }, customActions: { actionView })
        return UIHostingController(rootView: view)
    }

    func handleNotFound() -> UIViewController {
        let content = OnboardingContentData(
            image: .catFail,
            title: L10n.noWalletFound,
            subtitle: L10n.tryWithAccountOrUseAnAnotherPhoneNumber
        )
        let parameters = ChooseRestoreOptionParameters(
            isBackAvailable: false,
            content: content,
            options: [.socialApple, .socialGoogle, .custom],
            isStartAvailable: true
        )
        let chooseRestoreOptionViewModel = ChooseRestoreOptionViewModel(parameters: parameters)
        chooseRestoreOptionViewModel.optionChosen.sinkAsync(receiveValue: { [stateMachine] process in
            process.start {
                switch process.data {
                case .custom:
                    _ = try await stateMachine <- .enterPhone
                case .socialApple:
                    _ = try await stateMachine <- .requireSocial(provider: .apple)
                case .socialGoogle:
                    _ = try await stateMachine <- .requireSocial(provider: .google)
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
            self?.openHelp()
        }
        .store(in: &subscriptions)
        return UIHostingController(rootView: ChooseRestoreOptionView(viewModel: chooseRestoreOptionViewModel))
    }
}
