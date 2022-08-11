// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Resolver

struct ReactiveProcess<T> {
    let data: T
    let finish: (Error?) -> Void

    func start(_ compute: @escaping () async throws -> Void) {
        Task {
            do {
                try await compute()
                finish(nil)
            } catch {
                finish(error)
            }
        }
    }
}

class SocialSignInViewModel: BaseViewModel {
    enum Loading {
        case appleButton
        case googleButton
        case other
    }

    struct CoordinatorIO {
        let outBack: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let outTermAndCondition: PassthroughSubject<Void, Never> = .init()
        let outInfo: PassthroughSubject<Void, Never> = .init()
        let outLogin: PassthroughSubject<ReactiveProcess<SocialProvider>, Never> = .init()
    }

    @Injected var notificationService: NotificationService
    @Published var loading: Loading?
    private(set) var coordinatorIO: CoordinatorIO = .init()

    func onInfo() {
        guard loading == nil else { return }
    }

    func onBack() {
        guard loading == nil else { return }

        loading = .other
        let process: ReactiveProcess<Void> = .init(data: ()) { [weak self] error in
            if let error = error {
                self?.notificationService.showDefaultErrorNotification()
            }
            self?.loading = nil
        }
        coordinatorIO.outBack.send(process)
    }

    func onSignInTap(_ provider: SocialProvider) {
        guard loading == nil else { return }

        switch provider {
        case .apple: loading = .appleButton
        case .google: loading = .googleButton
        }

        let process: ReactiveProcess<SocialProvider> = .init(data: provider) { [weak self] error in
            switch error {
            case is SocialServiceError:
                break
            default:
                self?.notificationService.showDefaultErrorNotification()
            }
            self?.loading = nil
        }

        coordinatorIO.outLogin.send(process)
    }
}
