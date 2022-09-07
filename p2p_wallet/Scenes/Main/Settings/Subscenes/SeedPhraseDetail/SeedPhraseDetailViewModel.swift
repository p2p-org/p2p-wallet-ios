// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver

class SeedPhraseDetailViewModel: BaseViewModel {
    enum State {
        case lock
        case unlock
    }

    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var accountStorage: AccountStorageType
    @Injected private var clipboardManger: ClipboardManagerType
    @Injected private var notificationsService: NotificationService

    @Published var state: State
    @Published var isSliderOn: Bool = false

    var phrase: [String] {
        accountStorage.account?.phrase ?? []
    }

    init(initialState: State = .lock) {
        state = initialState
        super.init()
        $isSliderOn.sink { [weak self] isOn in
            guard isOn else { return }
            self?.unlock()
        }.store(in: &subscriptions)
    }

    func unlock() {
        authenticationHandler.authenticate(presentationStyle: .init(
            completion: { [weak self] _ in
                self?.state = .unlock
            }, onCancel: { [weak self] in
                self?.state = .lock
                self?.isSliderOn = false
            }
        ))
    }

    func copy() {
        clipboardManger.copyToClipboard(phrase.joined(separator: " "))
        notificationsService.showInAppNotification(.custom("👯", L10n.copiedToClipboard))
    }
}
