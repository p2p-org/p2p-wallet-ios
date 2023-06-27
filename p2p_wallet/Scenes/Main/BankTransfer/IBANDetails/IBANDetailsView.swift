import KeyAppUI
import SwiftUI

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
        var attrString = NSMutableAttributedString()
        attrString = attrString.text(L10n.yourMoneyIsHeldAndProtectedByLicensedBanks, size: 13, weight: .regular, color: Asset.Colors.night.color)
        attrString.append(NSAttributedString(string: " "))
        attrString.append(NSMutableAttributedString().text(L10n.learnMore, size: 13, weight: .regular, color: Asset.Colors.sky.color))
        return NSAttributedString(attributedString: attrString)
    }
}

struct IBANDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IBANDetailsView(viewModel: IBANDetailsViewModel())
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

