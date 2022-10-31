import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift

class SeedPhraseRestoreWalletViewModel: BaseViewModel {
    // MARK: - Dependencies

    @Injected private var notificationService: NotificationService
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Output

    let finishedWithSeed: PassthroughSubject<[String], Never> = .init()
    let back: PassthroughSubject<Void, Never> = .init()
    let info: PassthroughSubject<Void, Never> = .init()

    // MARK: - Properties

    // Word suggestions should appearr here
    @Published var suggestions = [String]()
    #if DEBUG
        @Published var seed =
            "crowd level crater figure super canyon silver wheel release cage zoo crucial sail aerobic road awesome fatal comfort canvas obscure grow mechanic spirit pave"
    #else
        @Published var seed = ""
    #endif
    @Published var canContinue: Bool = false
    @Published var isSeedFocused: Bool = false

    override init() {
        super.init()
        $seed.sink { [weak self] value in
            if value.split(separator: " ").count == 12 || value.split(separator: " ").count == 24 {
                self?.canContinue = true
            } else {
                self?.canContinue = false
            }
        }
        .store(in: &subscriptions)
    }

    func continueButtonTapped() {
        let seed = seed.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let phrase = try? Mnemonic(phrase: seed.components(separatedBy: " ")) {
            finishedWithSeed.send(phrase.phrase)
        } else {
            // show error
            notificationService.showToast(
                title: "😔",
                text: L10n.TheSeedPhraseDoesnTMatch.pleaseTryAgain
            )
        }
    }

    func paste() {
        guard let pasteboard = clipboardManager.stringFromClipboard() else { return }
        seed.append(pasteboard)
    }

    func clear() {
        seed = ""
    }
}
