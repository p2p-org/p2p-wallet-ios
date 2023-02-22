import SwiftUI
import KeyAppUI

struct HistoryErrorView: View {
    let action: () -> ()

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
            VStack(spacing: 20) {
                Image(uiImage: .catFail)
                    .padding(.bottom, 24) // 24 + 16
                Text(L10n.oopsSomethingHappened)
                    .apply(style: .text1)
                    .multilineTextAlignment(.center)
                TextButtonView(title: L10n.refresh, style: .second, size: .large, onPressed: action)
                    .frame(height: TextButton.Size.large.height)
                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
        }.edgesIgnoringSafeArea(.all)
    }
}

struct HistoryErrorView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryErrorView {
            debugPrint("NewHistoryErrorView_Previews Pressed")
        }
    }
}
