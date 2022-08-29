// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Reachability
import Resolver

struct SocialSignInParameters {
    let title: String
    let content: OnboardingContentData
    let appleButtonTitle: String
    let googleButtonTitle: String
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
    @Injected var reachability: Reachability

    @Published var loading: Loading?
    private(set) var coordinatorIO: CoordinatorIO = .init()

    @Published private(set) var title: String
    @Published private(set) var content: OnboardingContentData
    @Published private(set) var appleButtonTitle: String
    @Published private(set) var googleButtonTitle: String

    init(parameters: SocialSignInParameters) {
        title = parameters.title
        content = parameters.content
        appleButtonTitle = parameters.appleButtonTitle
        googleButtonTitle = parameters.googleButtonTitle
        super.init()
    }

    func onInfo() {
        guard loading == nil else { return }
    }

    func onBack() {
        guard loading == nil else { return }
        coordinatorIO.outBack.sendProcess()
    }

    func onSignInTap(_ provider: SocialProvider) {
        guard
            loading == nil,
            reachability.check()
        else { return }

        switch provider {
        case .apple: loading = .appleButton
        case .google: loading = .googleButton
        }

        notificationService.hideToasts()
        coordinatorIO.outLogin.sendProcess(data: provider) { [weak self] error in
            if let error = error {
                switch error {
                case SocialServiceError.cancelled:
                    break
                case is SocialServiceError:
                    self?.notificationService.showToast(
                        title: nil,
                        text: L10n.ThereIsAProblemWithServices.tryAgain(provider.rawValue.uppercaseFirst)
                    )
                default:
                    self?.notificationService.showDefaultErrorNotification()
                }
            }
            self?.loading = nil
        }
    }
}
