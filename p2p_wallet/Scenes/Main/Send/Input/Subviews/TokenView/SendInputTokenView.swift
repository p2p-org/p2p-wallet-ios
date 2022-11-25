import SwiftUI
import KeyAppUI

struct SendInputTokenView: View {
    @ObservedObject private var viewModel: SendInputTokenViewModel

    private let mainColor = Color(Asset.Colors.night.color)

    init(viewModel: SendInputTokenViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(spacing: 0) {
            CoinLogoImageViewRepresentable(size: 48, token: viewModel.token.token)
                .frame(width: 48, height: 48)
                .cornerRadius(radius: 48/2, corners: .allCorners)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.token.name)
                    .foregroundColor(mainColor)
                    .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .text2), weight: .semibold))

                HStack(spacing: 0) {
                    Image(uiImage: UIImage.buyWallet)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .frame(width: 16, height: 16)
                    Text(viewModel.amount?.tokenAmount(symbol: viewModel.token.token.symbol) ?? "")
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .apply(style: .text4)
                }
            }
            .padding(.vertical, 7)
            .padding(.leading, 12)

            Spacer()

            Text(viewModel.amountInCurrentFiat?.fiatAmount() ?? "")
                .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .text2), weight: .semibold))
                .foregroundColor(mainColor)
                .padding(EdgeInsets(top: 18, leading: 8, bottom: 18, trailing: 8))

            if viewModel.isTokenChoiceEnabled {
                Button(
                    action: viewModel.changeTokenPressed.send,
                    label: {
                        Image(uiImage: Asset.MaterialIcon.expandMore.image)
                            .renderingMode(.template)
                            .foregroundColor(mainColor)
                            .frame(width: 24, height: 24)
                    }
                )
                .frame(width: 24, height: 24)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))
        .background(RoundedRectangle(cornerRadius: 12))
        .foregroundColor(Color(Asset.Colors.snow.color))
    }
}

struct SendInputTokenView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(Asset.Colors.rain.color)
            SendInputTokenView(viewModel: SendInputTokenViewModel())
                .padding(.horizontal, 16)
        }
    }
}
