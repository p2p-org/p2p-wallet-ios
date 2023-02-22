import KeyAppUI
import SwiftUI

struct NewHistoryEmptyView: View {
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(uiImage: .moneybox)
                .padding(.bottom, 24) // 24 + 16
            Text(L10n.YourHistoryWillAppearHere.toGetStartedYouCan)
                .apply(style: .text1)
                .multilineTextAlignment(.center)
            TextButtonView(title: L10n.buyCrypto, style: .primary, size: .large, onPressed: primaryAction)
                .frame(height: TextButton.Size.large.height)
            TextButtonView(title: L10n.receive, style: .second, size: .large, onPressed: secondaryAction)
                .frame(height: TextButton.Size.large.height)
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(radius: 16, corners: .allCorners)
    }
}

struct NewHistoryEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        NewHistoryEmptyView {
            debugPrint("Primary action tapped")
        } secondaryAction: {
            debugPrint("Secondary action tapped")
        }
    }
}
