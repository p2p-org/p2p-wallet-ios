import SkeletonUI
import SwiftUI

struct AllTimePnLInfoBottomSheet: View {
    @ObservedObject var repository: PnLRepository
    @SwiftUI.Environment(\.dismiss) private var dismiss
    let mint: String? // mint == nil for total pnl

    var body: some View {
        VStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.lightGray))
                .frame(width: 31, height: 4)
                .padding(.vertical, 6)

            Image(.allTimePnl)
                .padding(.top, 20.88)

            explanationView
                .padding(.top, 16)

            button
                .padding(.top, 28)
                .padding(.bottom, 32)
        }
    }

    // MARK: - ViewBuilders

    @ViewBuilder
    private var explanationView: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(.transactionFee)
                .frame(width: 48, height: 48)

            let pnl = mint == nil ? repository.data?.total?.percent : repository.data?.pnlByMint[mint!]?.percent
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.allTheTime("\(pnl ?? "")%"))
                    .foregroundColor(Color(.night))
                    .font(uiFont: .font(of: .text1, weight: .semibold))
                    .skeleton(with: repository.data == nil && repository.isLoading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(
                    L10n.BasedOnAbsoluteAndRelativeProfitabilityOfEachTrade
                        .itShowsTheRelativePotentialProfitsOrLossesOfYourTradingStrategy
                )
                .font(uiFont: .font(of: .label1))
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(.cloud))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var button: some View {
        NewTextButton(
            title: L10n.gotIt,
            size: .large,
            style: .primaryWhite,
            expandable: true,
            action: {
                dismiss()
            }
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
}

// #Preview {
//    PnLInfoBottomSheet(
//        token: .init(
//            token: .unsupported(
//                tags: ["unknown"],
//                mint: "GWART6ijjvijdihuhvjhhdhjBn78Ee",
//                decimals: 6,
//                symbol: "GWART",
//                supply: 1_000_000_000
//            ),
//            userWallet: nil
//        )
//    ) {}
// }

// MARK: - Helpers

private extension String {
    var shortAddress: String {
        "\(prefix(6))...\(suffix(6))"
    }
}
