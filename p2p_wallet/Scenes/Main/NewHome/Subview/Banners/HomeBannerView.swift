import SwiftUI
import KeyAppUI

struct HomeBannerView: View {

    let backgroundColor: UIColor
    let image: UIImage
    let title: String
    let subtitle: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color(.clear)
                        .frame(height: 87)
                    Color(backgroundColor)
                        .frame(height: 200)
                        .cornerRadius(16)
                }
                Image(uiImage: image)
            }
            VStack(spacing: 19) {
                VStack(spacing: 8) {
                    Text(title)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .fontWeight(.bold)
                        .apply(style: .text1)
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .apply(style: .text3)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .padding(.horizontal, 24)
                }
                Button(
                    action: action,
                    label: {
                        Text(actionTitle)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .fontWeight(.semibold)
                            .apply(style: .text4)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                            .background(Color(Asset.Colors.snow.color))
                            .cornerRadius(8)
                            .padding(.horizontal, 24)
                    }
                )
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HomeBannerView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            HomeBannerView(
                backgroundColor: Asset.Colors.lightSea.color,
                image: .homeBannerPerson,
                title: L10n.topUpYourAccountToGetStarted,
                subtitle: L10n.makeYourFirstDepositOrBuyCryptoWithYourCreditCardOrApplePay,
                actionTitle: L10n.addMoney,
                action: { }
            )

            HomeBannerView(
                backgroundColor: Asset.Colors.lightSea.color,
                image: .kycClock,
                title: L10n.yourDocumentsVerificationIsPending,
                subtitle: L10n.usuallyItTakesAFewHours,
                actionTitle: L10n.view,
                action: { }
            )

            HomeBannerView(
                backgroundColor: Asset.Colors.lightGrass.color,
                image: .kycSend,
                title: L10n.verificationIsDone,
                subtitle: L10n.continueYourTopUpViaABankTransfer,
                actionTitle: L10n.topUp,
                action: { }
            )

            HomeBannerView(
                backgroundColor: Asset.Colors.lightSun.color,
                image: .kycShow,
                title: L10n.actionRequired,
                subtitle: L10n.pleaseCheckTheDetailsAndUpdateYourData,
                actionTitle: L10n.checkDetails,
                action: { }
            )

            HomeBannerView(
                backgroundColor: Asset.Colors.lightRose.color,
                image: .kycFail,
                title: "Verification is rejected",
                subtitle: "Add money via bank\ntransfer is unavailable",
                actionTitle: L10n.seeDetails,
                action: { }
            )
        }
        .listStyle(.plain)
    }
}
