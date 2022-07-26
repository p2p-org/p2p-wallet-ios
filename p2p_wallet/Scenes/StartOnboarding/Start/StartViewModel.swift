import Combine
import SwiftUI
import UIKit

enum StartViewModelOut {
    case createWallet
    case restoreWallet
    case openTerms
}

final class StartViewModel: BaseViewModel {
    @Published var data: [StartPageData] = [
        .init(
            image: .tokens,
            title: L10n.welcomeToKeyApp,
            subtitle: L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos
        ),
        .init(
            image: .tokens,
            title: "\(L10n.welcomeToKeyApp) 2",
            subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 2"
        ),
        .init(
            image: .tokens,
            title: "\(L10n.welcomeToKeyApp) 3",
            subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 3"
        ),
        .init(
            image: .tokens,
            title: "\(L10n.welcomeToKeyApp) 4",
            subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 4"
        ),
    ]

    @Published var currentIndex = 0
    @Published var result: StartViewModelOut?

    func createWalletPressed() {
        result = .createWallet
    }

    func alreadyHaveAWalletPressed() {
        result = .restoreWallet
    }

    func termsPressed() {
        result = .openTerms
    }
}
