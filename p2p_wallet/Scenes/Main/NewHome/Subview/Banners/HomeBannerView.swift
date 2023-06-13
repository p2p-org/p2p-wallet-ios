import SwiftUI
import KeyAppUI

struct HomeBannerViewParameters {
    let backgroundColor: UIColor
    let image: UIImage
    let title: String
    let subtitle: String
    let actionTitle: String
    let action: () -> Void
}

struct HomeBannerView: View {

    let params: HomeBannerViewParameters

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color(Asset.Colors.smoke.color)
                        .frame(height: 87)
                    Color(params.backgroundColor)
                        .frame(height: 200)
                        .cornerRadius(16)
                }
                Image(uiImage: params.image)
            }
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(params.title)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .fontWeight(.semibold)
                        .apply(style: .text1)
                        .multilineTextAlignment(.center)
                    Text(params.subtitle)
                        .apply(style: .text3)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .padding(.horizontal, 24)
                }
                Button(
                    action: params.action,
                    label: {
                        Text(params.actionTitle)
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
                params: HomeBannerViewParameters(
                    backgroundColor: Asset.Colors.lightSea.color,
                    image: .homeBannerPerson,
                    title: L10n.topUpYourAccountToGetStarted,
                    subtitle: L10n.makeYourFirstDepositOrBuyCryptoWithYourCreditCardOrApplePay,
                    actionTitle: L10n.addMoney,
                    action: { }
                )
            )

            HomeBannerView(
                params: HomeBannerViewParameters(
                    backgroundColor: Asset.Colors.lightSea.color,
                    image: .kycClock,
                    title: L10n.yourDocumentsVerificationIsPending,
                    subtitle: L10n.usuallyItTakesAFewHours,
                    actionTitle: L10n.view,
                    action: { }
                )
            )

            HomeBannerView(
                params: HomeBannerViewParameters(
                    backgroundColor: Asset.Colors.lightGrass.color,
                    image: .kycSend,
                    title: L10n.verificationIsDone,
                    subtitle: L10n.continueYourTopUpViaABankTransfer,
                    actionTitle: L10n.topUp,
                    action: { }
                )
            )

            HomeBannerView(
                params: HomeBannerViewParameters(
                    backgroundColor: Asset.Colors.lightSun.color,
                    image: .kycShow,
                    title: L10n.actionRequired,
                    subtitle: L10n.pleaseCheckTheDetailsAndUpdateYourData,
                    actionTitle: L10n.checkDetails,
                    action: { }
                )
            )

            HomeBannerView(
                params: HomeBannerViewParameters(
                    backgroundColor: Asset.Colors.lightRose.color,
                    image: .kycFail,
                    title: L10n.verificationIsRejected,
                    subtitle: L10n.addMoneyViaBankTransferIsUnavailable,
                    actionTitle: L10n.seeDetails,
                    action: { }
                )
            )
        }
        .listStyle(.plain)
    }
}
