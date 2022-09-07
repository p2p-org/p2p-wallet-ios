// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import KeyAppUI
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

    var thirdRowText: NSAttributedString {
        let firstAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(of: .text3, weight: .semibold),
            .foregroundColor: Asset.Colors.night.color,
        ]
        let secondAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(of: .text3),
            .foregroundColor: Asset.Colors.night.color,
        ]
        let firstString = NSMutableAttributedString(
            string: L10n.yourSeedPhraseMustNeverBeShared,
            attributes: firstAttributes
        )
        let secondString = NSAttributedString(
            string: L10n.keepItPrivateEvenFromUs,
            attributes: secondAttributes
        )
        firstString.append(secondString)
        return firstString
    }

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
        notificationsService.showInAppNotification(.custom("👯", L10n.copiedToClipboard))
    }
}
