// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Resolver

class SocialSignInAccountHasBeenUsedViewModel: NSObject, ViewModelType {
    struct Input {
        let onError: PassthroughSubject<Error, Never> = .init()
        let onBack: PassthroughSubject<Void, Never> = .init()
        let onInfo: PassthroughSubject<Void, Never> = .init()

        let useAnotherAccount: PassthroughSubject<Void, Never> = .init()
        let restoreThisWallet: PassthroughSubject<Void, Never> = .init()

        let isLoading: CurrentValueSubject<Bool, Never> = .init(false)
    }

    struct Output {
        let emailAddress: AnyPublisher<String, Never>
        let signInProvider: AnyPublisher<SocialProvider, Never>
        let isLoading: AnyPublisher<Bool, Never>
    }

    struct CoordinatorIO {
        let useAnotherAccount: AnyPublisher<Void, Never>
        let switchToRestoreFlow: AnyPublisher<Void, Never>
        let back: AnyPublisher<Void, Never>
    }

    var input: Input = .init()
    var output: Output
    let coordinatorIO: CoordinatorIO

    var subscriptions = [AnyCancellable]()

    @Injected var authService: AuthService
    @Injected var notificationService: NotificationService

    init(email: String, signInProvider: SocialProvider) {
        output = .init(
            emailAddress: CurrentValueSubject(email).eraseToAnyPublisher(),
            signInProvider: CurrentValueSubject(signInProvider).eraseToAnyPublisher(),
            isLoading: input.isLoading.eraseToAnyPublisher()
        )

        coordinatorIO = .init(
            useAnotherAccount: input.useAnotherAccount.eraseToAnyPublisher(),
            switchToRestoreFlow: input.restoreThisWallet.eraseToAnyPublisher(),
            back: input.onBack.eraseToAnyPublisher()
        )

        super.init()

        input.onError.sink { [weak self] error in
            DispatchQueue.main.async {
                self?.notificationService.showInAppNotification(.error(error))
            }
        }
        .store(in: &subscriptions)
    }
}
