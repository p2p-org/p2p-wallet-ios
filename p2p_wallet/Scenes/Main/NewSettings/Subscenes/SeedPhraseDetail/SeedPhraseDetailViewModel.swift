import AnalyticsManager
import Combine
import Foundation
import Resolver
import UIKit

class SeedPhraseDetailViewModel: BaseViewModel, ObservableObject {
    enum State {
        case lock
        case unlock
    }

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var accountStorage: AccountStorageType
    @Injected private var clipboardManger: ClipboardManagerType
    @Injected private var notificationsService: NotificationService

    @Published var state: State
    @Published var isSliderOn: Bool = false

    var thirdRowText: NSAttributedString {
        let firstAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(of: .text3, weight: .semibold),
            .foregroundColor: UIColor(resource: .night),
        ]
        let secondAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(of: .text3),
            .foregroundColor: UIColor(resource: .night),
        ]
        let firstString = NSMutableAttributedString(
            string: L10n.yourSeedPhraseMustNeverBeShared,
            attributes: firstAttributes
        )
        let secondString = NSAttributedString(
            string: " \(L10n.keepItPrivateEvenFromUs)",
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
        super.init()
        $isSliderOn.sink { [weak self] isOn in
            guard isOn else { return }
            self?.unlock()
        }.store(in: &subscriptions)
    }

    func unlock() {
        authenticationHandler.authenticate(presentationStyle: .init(
            options: [.fullscreen],
            completion: { [weak self] _ in
                self?.state = .unlock
            }, onCancel: { [weak self] in
                self?.state = .lock
                self?.isSliderOn = false
            }
        ))
    }

    func copy() {
        analyticsManager.log(event: .seedPhraseCopy)
        clipboardManger.copyToClipboard(phrase.joined(separator: " "))
        notificationsService.showInAppNotification(.custom("👯", L10n.copiedToClipboard))
    }
}
