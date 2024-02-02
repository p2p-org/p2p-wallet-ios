import Foundation
import SwiftUI

/// View of `CryptoEmpty` scene
struct CryptoEmptyView: View {
    // MARK: - Properties

    private let actionsPanelView: CryptoActionsPanelView
    private let banner: ReferralProgramBannerView?

    // MARK: - Initializer

    init(
        actionsPanelView: CryptoActionsPanelView,
        banner: ReferralProgramBannerView?
    ) {
        self.actionsPanelView = actionsPanelView
        self.banner = banner
    }

    // MARK: - View content

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                header
                if let banner {
                    banner
                        .padding(.horizontal, 16)
                }
                content
            }
        }
    }

    var header: some View {
        actionsPanelView
    }

    var content: some View {
        VStack(spacing: 24) {
            Image(.cryptoSplash)
            Text(L10n.WelcomeToYourCryptoPortfolio.exploreOver800TokensWithZeroFees)
                .font(uiFont: .font(of: .text1, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.night))
            Spacer()
        }
    }
}
