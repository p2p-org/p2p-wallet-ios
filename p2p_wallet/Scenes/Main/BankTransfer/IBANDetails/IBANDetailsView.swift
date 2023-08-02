import KeyAppUI
import SwiftUI
import BankTransfer

struct IBANDetailsView: View {
    @ObservedObject var viewModel: IBANDetailsViewModel

    var body: some View {
        ColoredBackground {
            ScrollView {
                VStack(spacing: 20) {
                    Text(L10n.useTheseDetailsToReceiveTransfersFromAEuroBankAccount)
                        .subtitleStyle()

                    VStack(spacing: 0) {
                        ForEach(viewModel.items, id: \.id) { item in
                            AnyRenderable(item: item)
                        }
                    }
                    .backgroundStyle(asset: Asset.Colors.snow)

                    VStack(spacing: 0) {
                        buildInformerView(title: .plain(L10n.transfersUsuallyTakeFrom1To3WorkingDaysToAppearInYourKeyAppAccount))

                        buildInformerView(title: .attributed(attributedTitle()))
                            .onTapGesture(perform: viewModel.learnMore.send)
                    }
                    .backgroundStyle(asset: Asset.Colors.rain)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func buildInformerView(title: BaseInformerViewItem.Title) -> BaseInformerView {
        BaseInformerView(
            data: BaseInformerViewItem(
                icon: .historyFilled,
                iconColor: Asset.Colors.night,
                title: title,
                backgroundColor: Asset.Colors.rain,
                iconBackgroundColor: Asset.Colors.smoke
            )
        )
    }

    private func attributedTitle() -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: 13, weight: .regular)
        let firstAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: Asset.Colors.night.color
        ]
        let firstString = NSMutableAttributedString(string: L10n.yourMoneyIsHeldAndProtectedByLicensedBanks, attributes: firstAttributes)
        let secondAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: Asset.Colors.sky.color
        ]
        let secondString = NSMutableAttributedString(string: " \(L10n.learnMore)", attributes: secondAttributes)
        return NSAttributedString(attributedString: firstString.appending(secondString))
    }
}

struct IBANDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IBANDetailsView(
                viewModel: IBANDetailsViewModel(
                    eurAccount: EURUserAccount(
                        accountID: "",
                        currency: "",
                        createdAt: "",
                        enriched: true,
                        availableBalance: nil,
                        iban: "IBAN",
                        bic: "BIC",
                        bankAccountHolderName: "Name Surname"
                    )
                )
            )
            .navigationTitle(L10n.euroAccount)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Helpers

private extension Text {
    func subtitleStyle() -> some View {
        self.apply(style: .text4)
        .foregroundColor(Color(asset: Asset.Colors.mountain))
        .multilineTextAlignment(.center)
    }
}

private extension VStack {
    func backgroundStyle(asset: ColorAsset) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(Color(asset: asset))
        )
    }
}

