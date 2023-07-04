import KeyAppUI
import SwiftUI
import BankTransfer

struct HomeSmallBannerView: View {

    let params: HomeBannerParameters

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(params.title)
                        .fontWeight(.semibold)
                        .apply(style: .text2)
                        .foregroundColor(Color(asset: Asset.Colors.night))

                    if let subtitle = params.subtitle {
                        Text(subtitle)
                            .apply(style: .text4)
                            .padding(.top, 4)
                    }

                    if let button = params.button {
                        NewTextButton(
                            title: button.title,
                            size: .small,
                            style: .primaryWhite,
                            isLoading: button.isLoading,
                            trailing: .arrowForward.withRenderingMode(.alwaysTemplate),
                            action: { button.handler() }
                        )
                        .padding(.top, 16)
                    }
                }

                Spacer()

                Image(uiImage: params.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: params.imageSize.width, height: params.imageSize.height)
                    .padding(.trailing, 16)
            }
            .padding(16)
            .background(Color(params.backgroundColor))
            .cornerRadius(radius: 24, corners: .allCorners)
        }
        .frame(height: 141)
    }
}

struct HomeSmallBannerView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ForEach(
                [StrigaKYCStatus.notStarted, .initiated, .pendingReview, .onHold, .approved, .rejected, .rejectedFinal], id: \.rawValue
            ) { element in
                HomeSmallBannerView(
                    params: HomeBannerParameters(
                        status: element,
                        action: { },
                        isLoading: true,
                        isSmallBanner: true
                    )
                )
            }
        }
        .listStyle(.plain)
    }
}
