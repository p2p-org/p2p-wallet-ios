import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift

class SeedPhraseRestoreWalletViewModel: ObservableObject {
    var bag = Set<AnyCancellable>()

    var coordinatorIO = CoordinatorIO()

    @Injected var notificationService: NotificationService
    @Injected var clipboardManager: ClipboardManagerType
    @Injected var analyticsManager: AnalyticsManager

    // Word suggestions should appearr here
    @Published var suggestions = [String]()
    #if DEBUG
        @Published var seed =
            "crowd level crater figure super canyon silver wheel release cage zoo crucial sail aerobic road awesome fatal comfort canvas obscure grow mechanic spirit pave"
    #else
        @Published var seed = ""
    #endif
    @Published var hasPasteboard: Bool = false

    func continueButtonTapped() {
        if let phrase = try? Mnemonic(phrase: seed.components(separatedBy: " ")) {
            coordinatorIO.finishedWithSeed.send(phrase.phrase)
        } else {
            // show error
            notificationService.showToast(
                title: "😔",
                text: L10n.ThereIsnTAWalletWithTheseSeedPhrase.checkItAgain
            )
        }
    }

    func back() {
        coordinatorIO.back.send(())
    }

    func info() {
        coordinatorIO.info.send(())
    }

    func paste() {
        guard let pasteboard = clipboardManager.stringFromClipboard() else { return }
        seed = pasteboard
    }

    func clear() {
        seed = ""
    }

    init() {
        // swiftlint:disable clipboard_direct_api
        UIPasteboard.general.hasStringsPublisher.sink { val in
            self.hasPasteboard = val != nil
        }.store(in: &bag)
        // swiftlint:enable clipboard_direct_api
    }

    struct CoordinatorIO {
        var finishedWithSeed: PassthroughSubject<[String], Never> = .init()
        var back: PassthroughSubject<Void, Never> = .init()
        var info: PassthroughSubject<Void, Never> = .init()
    }
}

extension UIPasteboard {
    var hasStringsPublisher: AnyPublisher<Bool, Never> {
        Just(hasStrings)
            .merge(
                with: NotificationCenter.default
                    .publisher(for: UIPasteboard.changedNotification, object: self)
                    .map { _ in self.hasStrings }
            )
            .merge(
                with: NotificationCenter.default
                    .publisher(for: UIApplication.didBecomeActiveNotification, object: nil)
                    .map { _ in self.hasStrings }
            )
            .eraseToAnyPublisher()
    }
}
