//
//  CustomShareDelegatedCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import Foundation
import Onboarding

class ReauthenticationCustomShareDelegatedCoordinator: DelegatedCoordinator<ReauthenticationCustomShareState> {
    override func buildViewController(for state: ReauthenticationCustomShareState) -> UIViewController? {
        switch state {
        case let .otpInput(phoneNumber, _, resendCounter):
            let vm = EnterSMSCodeViewModel(
                phone: phoneNumber,
                attemptCounter: resendCounter,
                strategy: .create
            )
            let vc = EnterSMSCodeViewController(viewModel: vm)
            vc.title = "Confirm your number"

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

        case .finish:
            return nil

        case .cancel:
            return nil
        }
    }
}
