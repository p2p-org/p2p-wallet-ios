import SwiftUI

struct SupportedTokensBannerView: View {
    var body: some View {
        HStack {
            Text(L10n.receiveTokensOnEthereumAndSolana)
                .apply(style: .text2)
                .frame(width: 200)
            Spacer()

            ZStack {
                Image(.ethereumIcon)
                    .cornerRadius(44)
                    .clipShape(Circle())
                Image(.solanaIcon)
                    .clipShape(Circle())
                    .offset(x: -33)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(Color(.rain))
        .cornerRadius(16)
    }
}

struct SupportedTokensBannerView_Previews: PreviewProvider {
    static var previews: some View {
        SupportedTokensBannerView()
    }
}
