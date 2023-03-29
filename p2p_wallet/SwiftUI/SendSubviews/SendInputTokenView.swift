import KeyAppUI
import SolanaSwift
import SwiftUI

struct SendInputTokenView: View {
    let mainColor = Color(Asset.Colors.night.color)
    let wallet: Wallet
    let amountInFiat: Double // It is separated from the wallet due to new SolanaAccount structures
    let changeAction: () -> Void
    let isChangeEnabled: Bool
    let skeleton: Bool

    init(wallet: Wallet, amountInFiat: Double, isChangeEnabled: Bool, skeleton: Bool = false, changeAction: @escaping () -> Void) {
        self.wallet = wallet
        self.amountInFiat = amountInFiat
        self.changeAction = changeAction
        self.isChangeEnabled = isChangeEnabled
        self.skeleton = skeleton
    }

    var body: some View {
        Button(action: changeAction) {
            HStack(spacing: 0) {
                CoinLogoImageViewRepresentable(size: 48, args: .token(wallet.token))
                    .skeleton(with: skeleton)
                    .frame(width: 48, height: 48)
                    .cornerRadius(radius: 48 / 2, corners: .allCorners)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(wallet.token.name)
                        .lineLimit(1)
                        .foregroundColor(mainColor)
                        .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .text2), weight: .semibold))
                        .skeleton(with: skeleton, size: .init(width: 120, height: 20))

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
                    .skeleton(with: skeleton, size: .init(width: 70, height: 16))
                }
                .padding(.vertical, 7)
                .padding(.leading, 12)

                Spacer()

                Text(amountInFiat.fiatAmountFormattedString(roundingMode: .down, customFormattForLessThan1E_2: true))
                    .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .text2), weight: .semibold))
                    .foregroundColor(mainColor)
                    .padding(EdgeInsets(top: 18, leading: 8, bottom: 18, trailing: 8))
                    .skeleton(with: skeleton, size: .init(width: 70, height: 20))

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
            SendInputTokenView(wallet: Wallet(token: .nativeSolana), amountInFiat: 1.0, isChangeEnabled: true, changeAction: {})
                .padding(.horizontal, 16)
        }
    }
}
