import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift

final class SeedPhraseRestoreWalletViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var notificationService: NotificationService
    @Injected private var clipboardManager: ClipboardManagerType

    // MARK: - Output

    let finishedWithSeed: PassthroughSubject<[String], Never> = .init()
    let back: PassthroughSubject<Void, Never> = .init()
    let info: PassthroughSubject<Void, Never> = .init()

    // MARK: - Properties

    // Word suggestions should appearr here
    @Published var suggestions = [String]()
    @Published var seed = ""
    @Published var canContinue: Bool = false
    @Published var isSeedFocused: Bool = false

    override init() {
        #if DEBUG
        seed = String.secretConfig("TEST_ACCOUNT_SEED_PHRASE")?.replacingOccurrences(of: "-", with: " ") ?? ""
        #endif
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
        seed = (seed + " " + pasteboard).seedPhraseFormatted
    }

    func clear() {
        seed = ""
    }
}
