import KeyAppKitCore
import KeyAppUI
import SwiftUI
import Wormhole

struct WormholeClaimFeeView: View {
    @ObservedObject var viewModel: WormholeClaimFeeViewModel

    var body: some View {
        VStack {
            Image(uiImage: .fee)
                .padding(.top, 33)

            HStack {
                Circle()
                    .fill(Color(Asset.Colors.smoke.color))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(uiImage: .lightningFilled)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .frame(width: 15, height: 21.5)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.howToClaimForFree)
                        .fontWeight(.semibold)
                        .apply(style: .text1)
                    Text(L10n.AllTransactionsOverAreFree.keyAppWillCoverAllFeesForYou("$50"))
                        .apply(style: .text4)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.all, 16)
            .background(Color(Asset.Colors.cloud.color))
            .cornerRadius(12)
            .padding(.top, 20)

            VStack(spacing: 24) {
                if let value = viewModel.fee.value {
                    WormholeFeeView(
                        title: "You will get",
                        subtitle: value.receive.crypto,
                        detail: value.receive.fiat,
                        isFree: value.receive.isFree,
                        isLoading: viewModel.fee.isFetching
                    )

                    if let networkFee = value.networkFee {
                        WormholeFeeView(
                            title: "Network Fee",
                            subtitle: networkFee.crypto,
                            detail: networkFee.fiat,
                            isFree: networkFee.isFree,
                            isLoading: viewModel.fee.isFetching
                        )
                    }

                    if let accountsFee = value.accountCreationFee {
                        WormholeFeeView(
                            title: "Account creation Fee",
                            subtitle: accountsFee.crypto,
                            detail: accountsFee.fiat,
                            isFree: accountsFee.isFree,
                            isLoading: viewModel.fee.isFetching
                        )
                    }

                    WormholeFeeView(
                        title: "Wormhole Bridge and Transaction Fee",
                        subtitle: value.wormholeBridgeAndTrxFee.crypto,
                        detail: value.wormholeBridgeAndTrxFee.fiat,
                        isFree: value.wormholeBridgeAndTrxFee.isFree,
                        isLoading: viewModel.fee.isFetching
                    )
                }
            }
            .padding(.top, 16)

            Button(
                action: {
                    viewModel.close()
                },
                label: {
                    Text(L10n.ok)
                        .font(uiFont: TextButton.Style.second.font(size: .large))
                        .foregroundColor(Color(TextButton.Style.second.foreground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(TextButton.Style.second.backgroundColor))
                        .cornerRadius(12)
                }
            )
            .padding(.top, 20)
        }
        .padding(.horizontal, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(UIColor(red: 0.82, green: 0.82, blue: 0.839, alpha: 1)))
                .frame(width: 30, height: 4)
                .padding(.top, 6),
            alignment: .top
        )
    }
}

private struct WormholeFeeView: View {
    let title: String
    let subtitle: String
    let detail: String
    let isFree: Bool
    let isLoading: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .apply(style: .text3)
                    .skeleton(with: isLoading, size: .init(width: 100, height: 16))
                Text(subtitle)
                    .apply(style: .label1)
                    .foregroundColor(Color(isFree ? Asset.Colors.mint.color : Asset.Colors.mountain.color))
                    .skeleton(with: isLoading, size: .init(width: 200, height: 16))
            }
            Spacer()
            Text(detail)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .skeleton(with: isLoading, size: .init(width: 100, height: 16))
        }
    }
}

struct WormholeClaimFee_Previews: PreviewProvider {
    static var previews: some View {
        WormholeClaimFeeView(
            viewModel: .init(
                receive: ("0.999717252 ETH", "~ $1,215.75", false),
                networkFee: ("Paid by Key App", "Free", true),
                accountCreationFee: ("0.999717252 WETH", "~ $1,215.75", false),
                wormholeBridgeAndTrxFee: ("0.999717252 WETH", "~ $1,215.75", false)
            )
        )
    }
}
