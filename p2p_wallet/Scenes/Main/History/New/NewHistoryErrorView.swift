import SwiftUI
import KeyAppUI

struct NewHistoryErrorView: View {
    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
            VStack(spacing: 20) {
                Image(uiImage: .catFail)
                    .padding(.bottom, 24) // 24 + 16
                Text("Oops! Something happened.")
                    .apply(style: .text1)
                    .multilineTextAlignment(.center)
                TextButtonView(title: L10n.refresh, style: .second, size: .large)
                    .frame(height: TextButton.Size.large.height)
                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
        }.edgesIgnoringSafeArea(.all)
    }
}

struct NewHistoryErrorView_Previews: PreviewProvider {
    static var previews: some View {
        NewHistoryErrorView()
    }
}
