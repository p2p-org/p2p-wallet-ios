import Foundation
import KeyAppUI
import SwiftUI

/// View of `CryptoEmpty` scene
struct CryptoEmptyView: View {
    // MARK: - Properties

    private let actionsPanelView: CryptoActionsPanelView

    // MARK: - Initializer

    init(
        actionsPanelView: CryptoActionsPanelView
    ) {
        self.actionsPanelView = actionsPanelView
    }

    // MARK: - View content

    var body: some View {
        VStack(spacing: 30) {
            header
            content
        }
    }

    var header: some View {
        actionsPanelView
    }

    var content: some View {
        VStack(spacing: 24) {
            Image(uiImage: UIImage.cryptoSplash)
            Text(L10n.WelcomeToYourCryptoPortfolio.exploreOver800TokensWithZeroFees)
                .font(uiFont: .font(of: .text1, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(Asset.Colors.night.color))
            Spacer()
        }
    }
}
