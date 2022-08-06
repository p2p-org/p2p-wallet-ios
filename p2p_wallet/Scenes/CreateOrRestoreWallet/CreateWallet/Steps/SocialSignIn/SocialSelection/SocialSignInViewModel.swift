// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Resolver

class SocialSignInViewModel: NSObject, ViewModelType {
    struct Input {
        let onBack: PassthroughSubject<Void, Never> = .init()
        let onError: PassthroughSubject<Error, Never> = .init()
        let onTermAndCondition: PassthroughSubject<Void, Never> = .init()
        let onInfo: PassthroughSubject<Void, Never> = .init()
        let onSignInWithApple: PassthroughSubject<Void, Never> = .init()
        let onSignInWithGoogle: PassthroughSubject<Void, Never> = .init()

        let isLoading: CurrentValueSubject<Bool, Never> = .init(false)

        fileprivate let onSuccessfulLogin: PassthroughSubject<SocialProvider, Never> = .init()
    }

    struct Output {
        let isLoading: AnyPublisher<Bool, Never>
    }

    struct CoordinatorIO {
        let onBack: AnyPublisher<Void, Never>
        let onTermAndCondition: AnyPublisher<Void, Never>
        let onInfo: AnyPublisher<Void, Never>
        let onLogin: AnyPublisher<SocialProvider, Never>
    }

    private(set) var input: Input = .init()
    private(set) var output: Output
    private(set) var coordinatorIO: CoordinatorIO

    @Injected var notificationService: NotificationService

    var subscriptions = [AnyCancellable]()

    override init() {
        output = .init(isLoading: input.isLoading.eraseToAnyPublisher())
        coordinatorIO = .init(
            onBack: input.onBack.eraseToAnyPublisher(),
            onTermAndCondition: input.onTermAndCondition.eraseToAnyPublisher(),
            onInfo: input.onInfo.eraseToAnyPublisher(),
            onLogin: input.onSuccessfulLogin.eraseToAnyPublisher()
        )

        super.init()

        input.onError.sink { [weak self] error in
            DispatchQueue.main.async {
                self?.notificationService.showInAppNotification(.error(error))
            }
        }
        .store(in: &subscriptions)

        input.onSignInWithApple.sink { [weak self] in
            self?.input.onSuccessfulLogin.send(.apple)
        }.store(in: &subscriptions)

        input.onSignInWithGoogle.sink { [weak self] in
            self?.input.onSuccessfulLogin.send(.google)
        }.store(in: &subscriptions)
    }
}
