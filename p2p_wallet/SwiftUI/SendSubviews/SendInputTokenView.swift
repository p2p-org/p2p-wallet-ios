import KeyAppUI
import SwiftUI
import SolanaSwift

struct SendInputTokenView: View {
    private let mainColor = Color(Asset.Colors.night.color)
    private let wallet: Wallet
    private let changeAction: () -> Void
    private let isChangeEnabled: Bool

    init(wallet: Wallet, isChangeEnabled: Bool, changeAction: @escaping () -> Void) {
        self.wallet = wallet
        self.changeAction = changeAction
        self.isChangeEnabled = isChangeEnabled
    }

    var body: some View {
        Button(action: changeAction) {
            HStack(spacing: 0) {
                CoinLogoImageViewRepresentable(size: 48, args: .token(wallet.token))
                    .frame(width: 48, height: 48)
                    .cornerRadius(radius: 48 / 2, corners: .allCorners)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(wallet.token.name)
                        .lineLimit(1)
                        .foregroundColor(mainColor)
                        .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .text2), weight: .semibold))

                    HStack(spacing: 0) {
                        Image(uiImage: UIImage.buyWallet)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .frame(width: 16, height: 16)
                        Text(wallet.amount?.toString(maximumFractionDigits: Int(wallet.token.decimals), roundingMode: .down) ?? "")
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .apply(style: .text4)
                            .lineLimit(1)
                        Spacer()
                            .frame(width: 2)
                        Text(wallet.token.symbol)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .apply(style: .text4)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                }
                .padding(.vertical, 7)
                .padding(.leading, 12)

                Spacer()

                Text(wallet.amountInCurrentFiat.fiatAmountFormattedString(roundingMode: .down, customFormattForLessThan1E_2: true))
                    .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .text2), weight: .semibold))
                    .foregroundColor(mainColor)
                    .padding(EdgeInsets(top: 18, leading: 8, bottom: 18, trailing: 8))

                if isChangeEnabled {
                    Image(uiImage: Asset.MaterialIcon.expandMore.image)
                        .renderingMode(.template)
                        .foregroundColor(mainColor)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))
            .background(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(Color(Asset.Colors.snow.color))
        }.allowsHitTesting(isChangeEnabled)
    }
}

struct SendInputTokenView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(Asset.Colors.rain.color)
            SendInputTokenView(wallet: Wallet(token: .nativeSolana), isChangeEnabled: true, changeAction: { })
                .padding(.horizontal, 16)
        }
    }
}
