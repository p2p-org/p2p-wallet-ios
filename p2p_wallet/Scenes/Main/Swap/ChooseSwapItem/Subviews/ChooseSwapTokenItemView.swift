import KeyAppUI
import SolanaSwift
import SwiftUI

struct ChooseSwapTokenItemView: View {
    private let token: SwapToken
    private let subtitle: String
    private let chosen: Bool
    private let fromToken: Bool

    init(
        token: SwapToken,
        chosen: Bool,
        fromToken: Bool
    ) {
        self.token = token
        self.chosen = chosen
        self.fromToken = fromToken
        if fromToken {
            subtitle = token.userWallet?.amount?.tokenAmountFormattedString(
                symbol: token.token.symbol, maximumFractionDigits: Int(token.token.decimals)
            ) ?? token.token.symbol
        } else {
            subtitle = token.token.symbol
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CoinLogoImageViewRepresentable(
                size: 48,
                args: .token(token.token)
            )
            .frame(width: 48, height: 48)
            .cornerRadius(radius: 48 / 2, corners: .allCorners)

            VStack(alignment: .leading, spacing: 4) {
                Text(token.token.name)
                    .font(uiFont: .font(of: .text3, weight: .bold))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .lineLimit(1)
                Text(subtitle)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
            rightView
        }.contentShape(Rectangle())
    }

    @ViewBuilder private var rightView: some View {
        if fromToken {
            if let amountInCurrentFiat = token.userWallet?.amountInCurrentFiat {
                Text(amountInCurrentFiat.fiatAmountFormattedString(customFormattForLessThan1E_2: true))
                    .font(uiFont: .font(of: .text3, weight: .semibold))
                    .foregroundColor(Color(Asset.Colors.night.color))
            } else {
                SwiftUI.EmptyView()
            }
        } else {
            if token.isPopular, !chosen {
                Text(L10n.popular)
                    .font(uiFont: .font(of: .text4))
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(Asset.Colors.rain.color))
                    .cornerRadius(32)
            } else {
                SwiftUI.EmptyView()
            }
        }
    }
}
