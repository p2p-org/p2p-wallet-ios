// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver

class SeedPhraseDetailViewModel: ObservableObject {
    enum State {
        case lock
        case unlock
    }

    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var accountStorage: AccountStorageType
    @Injected private var clipboardManger: ClipboardManagerType
    @Injected private var notificationsService: NotificationService

    @Published var state: State

    var phrase: [String] {
        accountStorage.account?.phrase ?? []
    }

    init(initialState: State = .lock) {
        state = initialState
    }

    func unlock() {
        authenticationHandler.authenticate(presentationStyle: .init(
            completion: { [weak self] _ in
                self?.state = .unlock
            }
        ))
    }

    func copy() {
        clipboardManger.copyToClipboard(phrase.joined(separator: " "))
        notificationsService.showInAppNotification(.done(L10n.seedPhraseCopiedToClipboard))
    }
}
