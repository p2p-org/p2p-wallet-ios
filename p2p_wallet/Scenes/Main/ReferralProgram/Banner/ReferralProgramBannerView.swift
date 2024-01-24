import SwiftUI

struct ReferralProgramBannerView: View {
    var shareAction: () -> Void
    var openDetails: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(L10n.refferalProgramm)
                    .font(uiFont: .font(of: .title3, weight: .semibold))
                Spacer()
                Image(uiImage: .init(resource: .referralIcon))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 141)
                    .padding(.trailing, 12)
            }
            HStack(spacing: 8) {
                NewTextButton(
                    title: L10n.shareMyLink,
                    size: .small,
                    style: .primary,
                    expandable: true,
                    trailing: UIImage(resource: .share3),
                    action: shareAction
                )
                NewTextButton(
                    title: L10n.openDetails,
                    size: .small,
                    style: .inverted,
                    expandable: true,
                    action: openDetails
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(uiColor: UIColor(resource: .cdf6Cd)))
        .cornerRadius(radius: 24, corners: .allCorners)
    }
}

#Preview {
    VStack {
        ReferralProgramBannerView(shareAction: {}, openDetails: {})
            .padding(.horizontal, 16)
    }
}
