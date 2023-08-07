import KeyAppUI
import SwiftUI

struct SupportedTokensBannerView: View {
    var body: some View {
        HStack {
            Text(L10n.receiveTokensOnEthereumAndSolana)
                .apply(style: .text2)
                .frame(width: 200)
            Spacer()

            ZStack {
                Image(uiImage: .ethereumIcon)
                    .cornerRadius(44)
                    .clipShape(Circle())
                Image(uiImage: .solanaIcon)
                    .clipShape(Circle())
                    .offset(x: -33)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(Color(Asset.Colors.rain.color))
        .cornerRadius(16)
    }
}

struct SupportedTokensBannerView_Previews: PreviewProvider {
    static var previews: some View {
        SupportedTokensBannerView()
    }
}
