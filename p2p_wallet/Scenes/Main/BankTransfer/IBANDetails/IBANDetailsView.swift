import BankTransfer
import KeyAppUI
import SwiftUI

struct IBANDetailsView: View {
    @ObservedObject var viewModel: IBANDetailsViewModel

    var body: some View {
        ColoredBackground {
            ScrollView {
                VStack(spacing: 20) {
                    BaseInformerView(data: BaseInformerViewItem(
                        icon: .sellPendingWarning,
                        iconColor: Asset.Colors.night,
                        title: L10n.yourBankAccountNameMustMatch(viewModel.informerName),
                        titleColor: Asset.Colors.cloud,
                        backgroundColor: Asset.Colors.night,
                        iconBackgroundColor: Asset.Colors.smoke
                    ))
                    .onTapGesture(perform: viewModel.warningTapped.send)

                    VStack(spacing: 0) {
                        ForEach(viewModel.items, id: \.id) { item in
                            AnyRenderable(item: item)
                        }
                    }
                    .backgroundStyle(asset: Asset.Colors.snow)

                    VStack(spacing: 0) {
                        buildSecondaryInformerView(title: L10n.ThisIsYourPersonalIBAN
                            .useThisDetailsToMakeTransfersThroughYourBankingApp, icon: .user)

                        buildSecondaryInformerView(title: L10n
                            .weUseSEPAInstantForBankTransfersAndTypicallyMoneyWillAppearInYourAccountInLessThanAMinute,
                            icon: .historyFilled)
                    }
                    .backgroundStyle(asset: Asset.Colors.rain)
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 16)
            }
        }
    }

    private func buildSecondaryInformerView(title: String, icon: UIImage) -> BaseInformerView {
        BaseInformerView(
            data: BaseInformerViewItem(
                icon: icon,
                iconColor: Asset.Colors.night,
                title: title,
                backgroundColor: Asset.Colors.rain,
                iconBackgroundColor: Asset.Colors.smoke
            )
        )
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

private extension VStack {
    func backgroundStyle(asset: ColorAsset) -> some View {
        background(
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(Color(asset: asset))
        )
    }
}
