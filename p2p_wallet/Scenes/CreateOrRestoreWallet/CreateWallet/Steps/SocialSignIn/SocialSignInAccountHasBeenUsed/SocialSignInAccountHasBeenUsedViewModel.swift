// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Reachability
import Resolver

class SocialSignInAccountHasBeenUsedViewModel: BaseViewModel {
    struct Coordinator {
        let useAnotherAccount: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let switchToRestoreFlow: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let info: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let back: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
    }

    let coordinator: Coordinator = .init()

    @Published var emailAddress: String
    @Published var signInProvider: SocialProvider
    @Published var loading: Bool = false

    @Injected var authService: AuthService
    @Injected var notificationService: NotificationService
    @Injected var reachability: Reachability

    init(email: String, signInProvider: SocialProvider) {
        emailAddress = email
        self.signInProvider = signInProvider

        super.init()
    }

    func back() {
        coordinator.back.sendProcess()
    }

    func info() {
        coordinator.info.sendProcess()
    }

    func switchToRestore() {
        coordinator.switchToRestoreFlow.sendProcess()
    }

    func userAnotherAccount() {
        guard
            loading == false,
            reachability.check()
        else { return }

        loading = true
        coordinator.useAnotherAccount.sendProcess { [weak self] error in
            if let error = error {
                switch error {
                case is SocialServiceError:
                    break
                default:
                    self?.notificationService.showDefaultErrorNotification()
                }
            }

            self?.loading = false
        }
    }

    func handleError(error: Error) {
        notificationService.showDefaultErrorNotification()
        DefaultLogManager.shared.log(event: error.readableDescription, logLevel: .error)
    }
}
