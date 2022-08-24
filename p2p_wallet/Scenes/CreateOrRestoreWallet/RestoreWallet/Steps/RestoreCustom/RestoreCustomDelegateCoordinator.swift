// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import CountriesAPI
import Foundation
import Onboarding
import SwiftUI

final class RestoreCustomDelegatedCoordinator: DelegatedCoordinator<RestoreCustomState> {
    override func buildViewController(for state: RestoreCustomState) -> UIViewController? {
        switch state {
        case .enterPhone:
            return handleEnterPhone()

        case let .enterOTP(phoneNumber, _, _):
            return handleEnterOtp(phoneNumber: phoneNumber)

        case let .otpNotDeliveredRequireSocial(phone):
            return handleOtpNotDeliveredRequireSocial(phone: phone)

        case let .otpNotDelivered(phone):
            return handleOtpNotDelivered(phone: phone)

        default:
            return nil
        }
    }

    private func openInfo() {
        let viewController = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        rootViewController?.present(viewController, animated: true)
    }

    private func selectCountry(selectedCountry: Country?) async throws -> Country? {
        guard let rootViewController = rootViewController else { return nil }
        let coordinator = ChoosePhoneCodeCoordinator(
            selectedCountry: selectedCountry,
            presentingViewController: rootViewController
        )
        return try await coordinator.start().async()
    }

    private func weCanTSMSYouContent(phone: String) -> OnboardingContentData {
        OnboardingContentData(
            image: .box,
            title: L10n.weCanTSMSYou,
            subtitle: L10n.SomethingWrongWithPhoneNumberOrSettings.ifYouWillWriteUsUseErrorCode10464(phone)
        )
    }
}

// MARK: - Single state handlers

private extension RestoreCustomDelegatedCoordinator {
    func handleEnterPhone() -> UIViewController {
        let viewModel = EnterPhoneNumberViewModel()
        let viewController = EnterPhoneNumberViewController(viewModel: viewModel)

        viewModel.coordinatorIO.selectFlag.sinkAsync { [weak self] selectedCountry in
            guard let result = try await self?.selectCountry(selectedCountry: selectedCountry) else { return }
            viewModel.coordinatorIO.countrySelected.send(result)
        }.store(in: &subscriptions)

        viewModel.coordinatorIO.phoneEntered.sinkAsync { [weak viewModel, stateMachine] phone in
            viewModel?.isLoading = true

            do {
                try await stateMachine <- .enterPhoneNumber(phoneNumber: phone)
            } catch {
                viewModel?.coordinatorIO.error.send(error)
            }
            viewModel?.isLoading = false

        }.store(in: &subscriptions)
        return viewController
    }

    func handleEnterOtp(phoneNumber: String) -> UIViewController {
        let viewModel = EnterSMSCodeViewModel(phone: phoneNumber)
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

        viewModel.coordinatorIO.goBack.sinkAsync { [weak viewModel, stateMachine] in
            viewModel?.isLoading = true
            do {
                try await stateMachine <- .back
            } catch {
                viewModel?.coordinatorIO.error.send(error)
            }
            viewModel?.isLoading = false
        }.store(in: &subscriptions)

        viewModel.coordinatorIO.onResend.sinkAsync { [weak viewModel, stateMachine] in
            viewModel?.isLoading = true
            do {
                try await stateMachine <- .resendOTP
            } catch {
                viewModel?.coordinatorIO.error.send(error)
            }
            viewModel?.isLoading = false
        }.store(in: &subscriptions)

        return viewController
    }

    func handleOtpNotDeliveredRequireSocial(phone: String) -> UIViewController {
        let parameters = ChooseRestoreOptionParameters(
            isBackAvailable: true,
            content: weCanTSMSYouContent(phone: phone),
            options: [.socialApple, .socialGoogle],
            isStartAvailable: true
        )

        let viewModel = ChooseRestoreOptionViewModel(parameters: parameters)
        viewModel.optionChosen.sinkAsync(receiveValue: { [stateMachine] process in
            switch process.data {
            case .socialApple:
                _ = try await stateMachine <- .requireSocial(provider: .apple)
            case .socialGoogle:
                _ = try await stateMachine <- .requireSocial(provider: .google)
            default: break
            }
        })
            .store(in: &subscriptions)
        viewModel.openStart.sinkAsync { [stateMachine] in
            _ = try await stateMachine <- .start
        }
        .store(in: &subscriptions)
        viewModel.openInfo.sink { [weak self] in
            self?.openInfo()
        }
        .store(in: &subscriptions)
        viewModel.back.sinkAsync { [stateMachine] in
            _ = try await stateMachine <- .back
        }
        .store(in: &subscriptions)

        return UIHostingController(rootView: ChooseRestoreOptionView(viewModel: viewModel))
    }

    func handleOtpNotDelivered(phone: String) -> UIViewController {
        let view = OnboardingBrokenScreen(
            title: "", contentData: weCanTSMSYouContent(phone: phone), back: { [stateMachine] in
                Task { _ = try await stateMachine <- .back }
            }, info: { [weak self] in
                self?.openInfo()
            }, help: { [stateMachine] in
                Task { _ = try await stateMachine <- .help }
            }
        )

        return UIHostingController(rootView: view)
    }
}
