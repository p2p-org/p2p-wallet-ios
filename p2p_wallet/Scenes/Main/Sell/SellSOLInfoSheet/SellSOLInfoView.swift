import SwiftUI
import KeyAppUI

struct SellSOLInfoView: View {

    let actionButtonPressed: () -> Void

    var body: some View {
        VStack(spacing: .zero) {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.vertical, 6)
            Spacer()
            Image(uiImage: .fee)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 215)
                .padding(.top, 18)
            Text(L10n.youCanOnlyCashOutSOL)
                .font(uiFont: .font(of: .title2, weight: .bold))
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.top, 21)
            Text(L10n.swapYourCryptocurrenciesToSOLToCashOut)
                .apply(style: .text1)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.top, 21)
            TextButtonView(
                title: L10n.gotIt,
                style: .primaryWhite,
                size: .large,
                onPressed: actionButtonPressed
            )
            .frame(height: TextButton.Size.large.height)
            .padding(.top, 48)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 16)
    }
}

struct SellSOLInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SellSOLInfoView(actionButtonPressed: {})
    }
}

