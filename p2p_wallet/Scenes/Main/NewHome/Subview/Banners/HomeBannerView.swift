import SwiftUI
import BankTransfer
import KeyAppUI

struct HomeBannerView: View {

    let params: HomeBannerParameters

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color(Asset.Colors.smoke.color)
                    .frame(height: 87)

                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text(params.title)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .fontWeight(.semibold)
                            .apply(style: .text1)
                            .multilineTextAlignment(.center)
                        if let subtitle = params.subtitle {
                            Text(subtitle)
                                .apply(style: .text3)
                                .minimumScaleFactor(0.5)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .foregroundColor(Color(Asset.Colors.night.color))
                        }
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
                        }
                    )
                }
                .padding(.horizontal, 24)
                .frame(height: 200)
                .background(Color(params.backgroundColor).cornerRadius(16))
            }

            Image(uiImage: params.image)
                .resizable()
                .frame(width: params.imageSize.width, height: params.imageSize.height)
                .aspectRatio(contentMode: .fit)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HomeBannerView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            HomeBannerView(
                params: HomeBannerParameters(
                    backgroundColor: .fern,
                    image: .homeBannerPerson,
                    imageSize: CGSize(width: 198, height: 142),
                    title: L10n.topUpYourAccountToGetStarted,
                    subtitle: L10n.makeYourFirstDepositOrBuyCryptoWithYourCreditCardOrApplePay,
                    actionTitle: L10n.addMoney,
                    action: { }
                )
            )

            ForEach([StrigaKYC.Status.notStarted, .initiated, .pendingReview, .onHold, .approved, .rejected, .rejectedFinal], id: \.rawValue) { element in
                HomeBannerView(params: HomeBannerParameters(status: element, action: { }, isSmallBanner: false))
            }
        }
        .listStyle(.plain)
    }
}
