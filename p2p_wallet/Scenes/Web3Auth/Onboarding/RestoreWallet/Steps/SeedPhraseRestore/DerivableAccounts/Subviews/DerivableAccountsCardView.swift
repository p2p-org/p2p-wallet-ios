import SwiftUI
import KeyAppUI

struct DerivableAccountsCardView: View {

    let derivationPath: String

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.derivationPath)
                    .font(uiFont: UIFont.font(of: .text3, weight: .semibold))
                    .foregroundColor(Color(Asset.Colors.night.color))

                Text(derivationPath)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }

            Spacer()

            Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                .renderingMode(.template)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .frame(width: 20, height: 25)
                .scaledToFill()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 28)
        .background(Color(Asset.Colors.snow.color))
        .addBorder(Color(Asset.Colors.rain.color), cornerRadius: 16)
        .shadow(color: .black.opacity(0.05), radius: 8 / UIScreen.main.scale)
    }
}
