// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import CountriesAPI
import Foundation
import Onboarding

class BindingPhoneNumberDelegatedCoordinator: DelegatedCoordinator<BindingPhoneNumberState> {
    override func buildViewController(for state: BindingPhoneNumberState) -> UIViewController? {
        switch state {
        case let .enterPhoneNumber(initialPhoneNumber, _):
            let mv = EnterPhoneNumberViewModel()
            mv.phone = initialPhoneNumber
            let vc = EnterPhoneNumberViewController(viewModel: mv)

            mv.coordinatorIO.selectFlag.sinkAsync { [weak self] selectedCountry in
                guard let result = try await self?.selectCountry(selectedCountry: selectedCountry) else { return }
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
        case let .enterOTP(phoneNumber, _):
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

    public func selectCountry(selectedCountry: Country?) async throws -> Country? {
        guard let rootViewController = rootViewController else { return nil }
        let coordinator = ChoosePhoneCodeCoordinator(
            selectedCountry: selectedCountry,
            presentingViewController: rootViewController
        )
        return try await coordinator.start().async()
    }
}
