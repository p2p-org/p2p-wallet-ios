import SwiftUI

struct ReferralProgramBannerView: View {
    var shareAction: () -> Void
    var openDetails: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(L10n.referralProgram.replacingOccurrences(of: " ", with: "\n"))
                    .font(uiFont: .font(of: .title3, weight: .semibold))
                Spacer()
                Image(uiImage: .init(resource: .referralIcon))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 141)
                    .padding(.trailing, 12)
            }
            HStack(spacing: 8) {
                // Must apply a button style for the correct behaviour inside a list
                // https://stackoverflow.com/a/70400079
                NewTextButton(
                    title: L10n.shareMyLink,
                    size: .small,
                    style: .primary,
                    expandable: true,
                    trailing: UIImage(resource: .share3),
                    action: shareAction
                )
                .buttonStyle(.plain)
                NewTextButton(
                    title: L10n.openDetails,
                    size: .small,
                    style: .inverted,
                    expandable: true,
                    action: openDetails
                )
                .buttonStyle(.plain)
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
