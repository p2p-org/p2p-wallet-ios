import SwiftUI
import KeyAppUI

struct BaseErrorView: View {

    struct Appearance {
        let actionButtonHorizontalOffset: CGFloat
        let imageTextPadding: CGFloat
    }

    let appearance: Appearance
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: appearance.imageTextPadding) {
                Image(.catFail)
                    .accessibilityIdentifier("BaseErrorView.image")
                VStack(spacing: 8) {
                    Text(L10n.sorry)
                        .foregroundColor(Color(.night))
                        .font(uiFont: .font(of: .title1, weight: .bold))
                        .accessibilityIdentifier("BaseErrorView.titleLabel")
                    Text(L10n.OopsSomethingWentWrong.pleaseTryAgainLater)
                        .foregroundColor(Color(.night))
                        .font(uiFont: .font(of: .text1))
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("BaseErrorView.subtitleLabel")
                }
            }
            Spacer()
            TextButtonView(
                title: actionTitle,
                style: .primaryWhite,
                size: .large,
                onPressed: action
            )
            .accessibilityIdentifier("BaseErrorView.actionButton")
            .frame(height: TextButton.Size.large.height)
            .padding(.bottom, 32)
            .padding(.horizontal, appearance.actionButtonHorizontalOffset)
        }
    }
}
