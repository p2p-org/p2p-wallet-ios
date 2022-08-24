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

        case let .enterOTP(phoneNumber, solPrivateKey, _):
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

        default:
            return nil
        }
    }

    public func showTermAndCondition() {
        let viewController = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        rootViewController?.present(viewController, animated: true)
    }

    public func selectCountry(selectedCountry: Country?) async throws -> Country? {
        guard let rootViewController = rootViewController else { return nil }
        let coordinator = ChoosePhoneCodeCoordinator(
            selectedCountry: selectedCountry,
            presentingViewController: rootViewController
        )
        return try await coordinator.start().async()
    }
}
