import KeyAppUI
import SwiftUI

struct SendInputTokenView: View {
    @ObservedObject private var viewModel: SendInputTokenViewModel

    private let mainColor = Color(Asset.Colors.night.color)

    init(viewModel: SendInputTokenViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.changeTokenPressed.send) {
            HStack(spacing: 0) {
                CoinLogoImageViewRepresentable(size: 48, token: viewModel.token.token)
                    .frame(width: 48, height: 48)
                    .cornerRadius(radius: 48 / 2, corners: .allCorners)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.tokenName)
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
                        Text(viewModel.amountText)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .apply(style: .text4)
                            .lineLimit(1)
                        Spacer()
                            .frame(width: 2)
                        Text(viewModel.amountCurrency)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .apply(style: .text4)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                }
                .padding(.vertical, 7)
                .padding(.leading, 12)

                Spacer()

                Text(viewModel.amountInCurrentFiat)
                    .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .text2), weight: .semibold))
                    .foregroundColor(mainColor)
                    .padding(EdgeInsets(top: 18, leading: 8, bottom: 18, trailing: 8))

                if viewModel.isTokenChoiceEnabled {
                    Image(uiImage: Asset.MaterialIcon.expandMore.image)
                        .renderingMode(.template)
                        .foregroundColor(mainColor)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))
            .background(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(Color(Asset.Colors.snow.color))
        }.allowsHitTesting(viewModel.isTokenChoiceEnabled)
    }
}

struct SendInputTokenView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(Asset.Colors.rain.color)
            SendInputTokenView(viewModel: SendInputTokenViewModel(initialToken: .init(token: .nativeSolana)))
                .padding(.horizontal, 16)
        }
    }
}
