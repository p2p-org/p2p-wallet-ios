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
    let isBackAvailable: Bool
}

class SocialSignInViewModel: BaseViewModel {
    enum Loading {
        case appleButton
        case googleButton
        case other
    }

    @Injected var notificationService: NotificationService
    @Injected var reachability: Reachability

    @Published var loading: Loading?

    @Published private(set) var title: String
    @Published private(set) var content: OnboardingContentData
    @Published private(set) var appleButtonTitle: String
    @Published private(set) var googleButtonTitle: String

    let isBackAvailable: Bool
    let outBack: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
    let outInfo: PassthroughSubject<Void, Never> = .init()
    let outLogin: PassthroughSubject<ReactiveProcess<SocialProvider>, Never> = .init()

    init(parameters: SocialSignInParameters) {
        title = parameters.title
        content = parameters.content
        appleButtonTitle = parameters.appleButtonTitle
        googleButtonTitle = parameters.googleButtonTitle
        isBackAvailable = parameters.isBackAvailable
        super.init()
    }

    func onInfo() {
        guard loading == nil else { return }
        outInfo.send()
    }

    func onBack() {
        guard loading == nil else { return }
        outBack.sendProcess()
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
        outLogin.sendProcess(data: provider) { [weak self] error in
            if let error = error {
                switch error {
                case is SocialServiceError:
                    switch error as! SocialServiceError {
                    case .cancelled: break
                    default:
                        self?.notificationService.showToast(
                            title: nil,
                            text: L10n.ThereIsAProblemWithServices.tryAgain(provider.rawValue.uppercaseFirst)
                        )
                    }
                default:
                    self?.notificationService.showDefaultErrorNotification()
                }
            }
            self?.loading = nil
        }
    }
}
