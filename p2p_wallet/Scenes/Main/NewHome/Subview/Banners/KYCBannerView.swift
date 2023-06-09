import KeyAppUI
import SwiftUI
import BankTransfer

struct KYCBannerView: View {

    let params: KYCBannerParameters
    let action: () -> Void

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

                    Button(action: action) {
                        HStack(spacing: 8) {
                            Text(params.actionTitle)
                                .fontWeight(.medium)
                                .apply(style: .text4)
                                .padding(.vertical, 8)
                                .foregroundColor(Color(asset: Asset.Colors.snow))
                            Image(uiImage: .arrowForward)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(Color(asset: Asset.Colors.snow))
                        }
                        .padding(.leading, 16)
                        .padding(.trailing, 12)
                    }
                    .background(Color(asset: Asset.Colors.night))
                    .cornerRadius(radius: 8, corners: .allCorners)
                    .padding(.top, 16)
                }

                Spacer()

                Image(uiImage: params.image)
                    .resizable()
                    .scaledToFit()
                    .frame(minWidth: 100, maxWidth: 120)
            }
            .padding(16)
            .background(params.backgroundColor)
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
            ForEach([StrigaKYC.Status.notStarted, .initiated, .pendingReview, .onHold, .approved, .rejected, .rejectedFinal], id: \.rawValue) { element in
                KYCBannerView(params: KYCBannerParameters(status: element), action: { })
            }
        }
        .listStyle(.plain)
    }
}
