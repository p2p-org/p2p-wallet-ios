//
//  ReAuthSocialSignInViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import Combine
import Foundation
import Onboarding
import Resolver

class ReAuthSocialSignInViewModel: BaseViewModel, ObservableObject {
    @Injected var notificationService: NotificationService

    @Published var loading: Bool = false

    @Published var provider: SocialProvider
    @Published var buttonTitle: String = L10n.continueWithGoogle

    let onContinue: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()

    let onClose: PassthroughSubject<Void, Never> = .init()
    
    init(socialProvider: SocialProvider) {
        provider = socialProvider
    }

    func signIn() {
        loading = true
        onContinue.sendProcess { [weak self] error in
            self?.loading = false 

            if let error {
                self?.notificationService.showInAppNotification(.error(error))
            }
        }
    }
    
    func close() {
        onClose.send()
    }
}

extension ReAuthSocialSignInViewModel {
    enum Action {
        case onContinue
    }
}
