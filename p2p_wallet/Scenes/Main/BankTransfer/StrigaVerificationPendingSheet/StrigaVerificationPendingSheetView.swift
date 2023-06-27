import KeyAppUI
import SwiftUI

struct StrigaVerificationPendingSheetView: View {
    let action: () -> Void

    var body: some View {
        ColoredBackground {
            VStack {
                RoundedRectangle(cornerRadius: 2, style: .circular)
                    .fill(Color(Asset.Colors.rain.color))
                    .frame(width: 31, height: 4)
                    .padding(.top, 6)

                VStack(spacing: 24) {
                    Image(uiImage: .kycClock)
                        .frame(width: 100, height: 100)

                    Text(L10n.yourKYCVerificationIsPending)
                        .apply(style: .title2, weight: .bold)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(L10n.weWillUpdateTheStatusOnceItIsFinished)
                        .apply(style: .text3)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    NewTextButton(title: L10n.gotIt, style: .primary, expandable: true, action: action)
                        .padding(.top, 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .cornerRadius(20)
    }
}

struct StrigaVerificationPendingSheetView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StrigaVerificationPendingSheetView(action: { })
        }
    }
}
