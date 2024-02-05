import SwiftUI

struct NonStrictTokenConfirmationView: View {
    let token: SwapToken?
    var onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.lightGray))
                .frame(width: 31, height: 4)
                .padding(.vertical, 6)

            Image(.nonStrictToken)
                .padding(.top, 20.88)

            explanationView
                .padding(.top, 16)

            buttons
                .padding(.top, 28)
                .padding(.bottom, 32)
        }
    }

    // MARK: - ViewBuilders

    @ViewBuilder
    private var explanationView: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(.infoGray20)
                .padding(14)
                .background(Circle()
                    .fill(Color(.smoke)))

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.theTokenIsOutOfTheStrictList(token?.token.symbol ?? token?.token.mintAddress.prefix(6) ?? ""))
                    .foregroundColor(Color(.night))
                    .font(uiFont: .font(of: .text1, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.makeSureTheMintAddressIsCorrectBeforeConfirming(token?.token.mintAddress.shortAddress ?? ""))
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
    private var buttons: some View {
        VStack(spacing: 16) {
            NewTextButton(
                title: L10n.confirmSelection,
                size: .large,
                style: .primaryWhite,
                expandable: true,
                action: onConfirm
            )

            // Learn more
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NonStrictTokenConfirmationView(
        token: .init(
            token: .unsupported(
                tags: ["unknown"],
                mint: "GWART6ijjvijdihuhvjhhdhjBn78Ee",
                decimals: 6,
                symbol: "GWART",
                supply: 1_000_000_000
            ),
            userWallet: nil
        )
    ) {}
}
