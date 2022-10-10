import KeyAppUI
import SwiftUI

struct InvestSolendHeaderView: View {
    let title: String
    let logoURLString: String?
    let subtitle: String?
    let rightTitle: String?
    let rightSubtitle: String?
    @Binding var showDisclosure: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let logo = logoURLString, let url = URL(string: logo) {
                ImageView(withURL: url)
                    .clipShape(Circle())
                    .frame(width: 48, height: 48)
            } else {
                Circle()
                    .fill(Color(Asset.Colors.mountain.color))
                    .frame(width: 48, height: 48)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .apply(style: .text2)
                Text(subtitle)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .apply(style: .label1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                if let rightTitle = rightTitle {
                    Text(rightTitle)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                }
                if let rightSubtitle = rightSubtitle {
                    Text(rightSubtitle)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .apply(style: .label1)
                }
            }
            if showDisclosure {
                Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .padding(.trailing, -8)
                    .padding(.leading, -4)
            }
        }
        .frame(height: 64)
    }
}
