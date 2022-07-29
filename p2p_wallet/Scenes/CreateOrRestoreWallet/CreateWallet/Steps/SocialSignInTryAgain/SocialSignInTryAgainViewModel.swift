// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Combine
import Foundation
import Onboarding
import Resolver

class SocialSignInTryAgainViewModel: NSObject, ViewModelType {
    struct Input {
        let onTryAgain: PassthroughSubject<Void, Never> = .init()
        let onStartScreen: PassthroughSubject<Void, Never> = .init()
        let onError: PassthroughSubject<Error, Never> = .init()

        let isLoading: CurrentValueSubject<Bool, Never> = .init(false)
    }

    struct Output {
        let isLoading: AnyPublisher<Bool, Never>
    }

    struct CoordinatorIO {
        let tryAgain: PassthroughSubject<SocialAuthResponse, Never> = .init()
        let startScreen: AnyPublisher<Void, Never>
    }

    @Injected var authService: AuthService
    @Injected var notificationService: NotificationService

    private(set) var input: Input = .init()
    private(set) var output: Output
    private(set) var coordinator: CoordinatorIO
    let signInProvider: SignInProvider
    var subscriptions = [AnyCancellable]()

    init(signInProvider: SignInProvider) {
        self.signInProvider = signInProvider

        output = .init(
            isLoading: input.isLoading.eraseToAnyPublisher()
        )

        coordinator = .init(
            startScreen: input.onStartScreen.eraseToAnyPublisher()
        )

        super.init()

        input.onTryAgain.sink { [weak self] in self?.tryAgain() }
            .store(in: &subscriptions)
    }

    func tryAgain() {
        Task {
            input.isLoading.send(true)
            defer { input.isLoading.send(false) }

            do {
                let authResult = try await authService.socialSignIn(signInProvider.socialType)
                coordinator.tryAgain.send(authResult)
            } catch let e {
                DispatchQueue.main.async {
                    self.notificationService.showInAppNotification(.error(e))
                }
            }
        }
    }
}
