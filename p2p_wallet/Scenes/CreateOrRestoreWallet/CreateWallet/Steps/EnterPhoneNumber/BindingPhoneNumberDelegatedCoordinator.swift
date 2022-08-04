// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import CountriesAPI
import Foundation
import Onboarding

@MainActor
class BindingPhoneNumberDelegatedCoordinator {
    typealias EventHandler = (_ event: BindingPhoneNumberEvent) async throws -> Void

    var subscriptions = [AnyCancellable]()

    let eventHandler: EventHandler
    var rootViewController: UIViewController?

    init(eventHandler: @escaping EventHandler) {
        self.eventHandler = eventHandler
    }

    func buildViewController(for state: BindingPhoneNumberState) -> UIViewController? {
        switch state {
        case let .enterPhoneNumber(initialPhoneNumber):
            // TODO: pass initialPhoneNumber to view model
            let mv = EnterPhoneNumberViewModel()
            let vc = EnterPhoneNumberViewController(viewModel: mv)

            mv.coordinatorIO.selectFlag.sinkAsync { [weak self] in
                guard let result = try await self?.selectCountry() else { return }
                mv.coordinatorIO.countrySelected.send(result)
            }.store(in: &subscriptions)

            mv.coordinatorIO.phoneEntered.sinkAsync { [weak self] phone in
                try await self?.eventHandler(.enterPhoneNumber(phoneNumber: phone))
            }.store(in: &subscriptions)
            return vc
        case let .enterOTP(phoneNumber):
            let vm = EnterSMSCodeViewModel(phone: phoneNumber)
            let vc = EnterSMSCodeViewController(viewModel: vm)

            vm.coordinatorIO.goBack.sinkAsync { [weak self] in
                try await self?.eventHandler(.back)
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

    public func selectCountry() async throws -> Country? {
        guard let rootViewController = rootViewController else { return nil }
        let coordinator = ChoosePhoneCodeCoordinator(
            selectedCountry: nil,
            presentingViewController: rootViewController
        )
        return try await coordinator.start().async()
    }
}
