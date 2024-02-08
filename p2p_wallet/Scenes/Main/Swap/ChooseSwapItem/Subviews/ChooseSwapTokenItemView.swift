import KeyAppKitCore
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

        let formattedMint = RecipientFormatter.format(destination: token.mintAddress)

        if fromToken {
            let amount = token.userWallet?.amount?.tokenAmountFormattedString(
                symbol: token.token.symbol, maximumFractionDigits: Int(token.token.decimals)
            )

            if let amount {
                subtitle = "\(amount) • \(formattedMint)"
            } else {
                subtitle = "\(token.token.symbol) • \(formattedMint)"
            }
        } else {
            subtitle = "\(token.token.symbol) • \(formattedMint)"
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
                HStack {
                    Text(token.token.name)
                        .font(uiFont: .font(of: .text3, weight: .bold))
                        .foregroundColor(Color(.night))
                        .lineLimit(1)

                    Text(token.isNonStrict ? " ⚠" : "")
                        .font(uiFont: .font(of: .text3, weight: .bold))
                        .foregroundColor(Color(.night))
                        .lineLimit(1)
                }
                Text(subtitle)
                    .apply(style: .label1)
                    .foregroundColor(Color(.mountain))
            }
            Spacer()
            rightView
        }.contentShape(Rectangle())
    }

    @ViewBuilder private var rightView: some View {
        if fromToken {
            if let amountInFiat = token.userWallet?.amountInFiat {
                Text(CurrencyFormatter().string(amount: amountInFiat))
                    .font(uiFont: .font(of: .text3, weight: .semibold))
                    .foregroundColor(Color(.night))
            } else {
                SwiftUI.EmptyView()
            }
        } else {
            if token.isPopular, !chosen {
                Text(L10n.popular)
                    .font(uiFont: .font(of: .text4))
                    .foregroundColor(Color(.mountain))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.rain))
                    .cornerRadius(32)
            } else {
                SwiftUI.EmptyView()
            }
        }
    }
}
