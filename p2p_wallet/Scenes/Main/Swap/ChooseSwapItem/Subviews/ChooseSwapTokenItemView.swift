import KeyAppUI
import SwiftUI
import SolanaSwift

struct ChooseSwapTokenItemView: View {
    let token: SwapToken

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CoinLogoImageViewRepresentable(
                size: 48,
                token: SolanaSwift.Token(jupiterToken: token.jupiterToken)
            )
            .frame(width: 48, height: 48)
            .cornerRadius(radius: 48/2, corners: .allCorners)

            VStack(alignment: .leading, spacing: 4) {
                Text(token.jupiterToken.name)
                    .font(uiFont: .font(of: .text3, weight: .bold))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .lineLimit(1)
                Text(token.jupiterToken.symbol)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
            if let amountInCurrentFiat = token.userWallet?.amountInCurrentFiat {
                Text(amountInCurrentFiat.fiatAmountFormattedString(customFormattForLessThan1E_2: true))
                    .font(uiFont: .font(of: .text3, weight: .semibold))
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
        }.contentShape(Rectangle())
    }
}
