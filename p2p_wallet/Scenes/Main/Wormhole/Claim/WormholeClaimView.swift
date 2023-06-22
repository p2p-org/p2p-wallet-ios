import KeyAppUI
import Kingfisher
import SolanaSwift
import SwiftUI

struct WormholeClaimView: View {
    @ObservedObject var viewModel: WormholeClaimViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text(L10n.confirmClaimingTheTokens)
                .fontWeight(.bold)
                .apply(style: .title2)
                .multilineTextAlignment(.center)
                .padding(.top, 40)

            // Logo

            if let url = viewModel.model.icon {
                KFImage
                    .url(url)
                    .setProcessor(
                        DownsamplingImageProcessor(size: .init(width: 128, height: 128))
                            |> RoundCornerImageProcessor(cornerRadius: 64)
                    )
                    .resizable()
                    .diskCacheExpiration(.days(7))
                    .fade(duration: 0.1)
                    .frame(width: 64, height: 64)
                    .padding(.top, 28)

            } else {
                Circle()
                    .fill(Color(Asset.Colors.smoke.color))
                    .overlay(
                        Image(.imageOutlineIcon)
                            .renderingMode(.template)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                    )
                    .clipped()
                    .frame(width: 64, height: 64)
                    .padding(.top, 28)
            }

            // Amount in crypto
            Text(viewModel.model.title)
                .fontWeight(.bold)
                .apply(style: .title1)
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            // Amount in currency
            if !viewModel.model.subtitle.isEmpty {
                Text(viewModel.model.subtitle)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 0) {
                // Fee
                HStack(alignment: .center) {
                    // Title
                    Text(L10n.fees)
                        .apply(style: .text3)
                    Spacer()

                    if viewModel.model.isOpenFeesVisible {
                        // Amount
                        Text(viewModel.model.fees)
                            .apply(style: .label1)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .skeleton(
                                with: viewModel.model.isLoading,
                                size: .init(width: 100, height: 24)
                            )
                        // Button
                        Button {
                            viewModel.openFees()
                        } label: {
                            Image(.info)
                                .resizable()
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .frame(width: 20, height: 20)
                        }
                        .disabled(!viewModel.model.claimButtonEnable)
                    } else {
                        // Amount
                        Text(viewModel.model.fees)
                            .apply(style: .text3)
                            .skeleton(
                                with: viewModel.model.isLoading,
                                size: .init(width: 100, height: 24)
                            )
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)

                if viewModel.model.getAmount != nil {
                    Divider()
                        .padding(.leading, 20)
                    HStack(alignment: .center) {
                        Text(L10n.youWillGet)
                            .apply(style: .text3)
                        Spacer()

                        // Amount
                        Text(viewModel.model.getAmount ?? "")
                            .apply(style: .label1)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .skeleton(
                                with: viewModel.model.isLoading,
                                size: .init(width: 100, height: 24)
                            )
                            .if(viewModel.model.isLoading) { view in
                                view.padding(.trailing, 25)
                            }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(Asset.Colors.snow.color))
            )
            .padding(.top, 32)

            if viewModel.model.shouldShowBanner {
                if let freeFeeLimit = viewModel.freeFeeLimit.value {
                    RefundBannerReceiveView(
                        item: .init(text: L10n.weRefundBridgingCostsForAnyTransactionsOver(freeFeeLimit))
                    )
                    .padding(.top, 16)
                }
            }

            Spacer()

            // Button
            TextButtonView(title: viewModel.model.claimButtonTitle, style: .primaryWhite, size: .large) {
                viewModel.claim()
            }
            .disabled(!viewModel.model.claimButtonEnable)
            .frame(height: TextButton.Size.large.height)
        }
        .padding(.horizontal, 16)
        .background(
            Color(Asset.Colors.smoke.color)
                .ignoresSafeArea()
        )
    }
}

struct WormholeClaimView_Previews: PreviewProvider {
    static var previews: some View {
        WormholeClaimView(viewModel:
            .init(
                model: .init(
                    icon: URL(string: Token.eth.logoURI!)!,
                    title: "0.999717252 ETH",
                    subtitle: "~ $1 219.87",
                    claimButtonTitle: "Claim 0.999717252 ETH",
                    claimButtonEnable: true,
                    isOpenFeesVisible: true,
                    shouldShowBanner: true,
                    fees: "$76.23",
                    feesButtonEnable: true,
                    isLoading: false
                )
            ))
    }
}
