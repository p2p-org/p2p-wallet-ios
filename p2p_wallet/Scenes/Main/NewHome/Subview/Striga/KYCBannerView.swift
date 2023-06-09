import KeyAppUI
import SwiftUI

struct KYCBannerView: View {

    let title: String
    let subtitle: String?
    let actionTitle: String
    let image: UIImage
    let backgroundColor: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .fontWeight(.semibold)
                        .apply(style: .text2)
                        .foregroundColor(Color(asset: Asset.Colors.night))

                    if let subtitle {
                        Text(subtitle)
                            .apply(style: .text4)
                            .padding(.top, 4)
                    }

                    NewTextButton(
                        title: actionTitle,
                        size: .small,
                        style: .primaryWhite,
                        trailing: .arrowForward,
                        action: { }
                    )
                    .padding(.top, 16)
                }

                Spacer()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(minWidth: 100, maxWidth: 120)
            }
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(radius: 24, corners: .allCorners)

            Button(action: { }) {
                Image(uiImage: Asset.MaterialIcon.close.image)
                    .renderingMode(.template)
                    .foregroundColor(Color(asset: Asset.Colors.night))
                    .padding(12)
            }
        }
        .frame(height: 141)
    }
}

struct KYCBannerView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            KYCBannerView(
                title: L10n.yourDocumentsVerificationIsPending,
                subtitle: L10n.usuallyItTakesAFewHours,
                actionTitle: L10n.view,
                image: .kycClock,
                backgroundColor: Color(asset: Asset.Colors.lightSea)
            )

            KYCBannerView(
                title: L10n.finishIdentityVerificationToSendYourMoneyWorldwide,
                subtitle: nil,
                actionTitle: L10n.continue,
                image: .startThree,
                backgroundColor: Color(asset: Asset.Colors.lightSea)
            )

            KYCBannerView(
                title: L10n.verificationIsDone,
                subtitle: L10n.continueYourTopUpViaABankTransfer,
                actionTitle: L10n.topUp,
                image: .kycSend,
                backgroundColor: Color(asset: Asset.Colors.lightGrass)
            )

            KYCBannerView(
                title: L10n.actionRequired,
                subtitle: L10n.pleaseCheckTheDetailsAndUpdateYourData,
                actionTitle: L10n.checkDetails,
                image: .kycShow,
                backgroundColor: Color(asset: Asset.Colors.lightSun)
            )

            KYCBannerView(
                title: L10n.sorryBankTransferIsUnavailableForYou,
                subtitle: nil,
                actionTitle: L10n.seeDetails,
                image: .kycFail,
                backgroundColor: Color(asset: Asset.Colors.lightRose)
            )
        }
        .listStyle(.plain)
        .padding(16)
    }
}
