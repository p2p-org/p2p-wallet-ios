import SwiftUI

struct DerivableAccountsCardView: View {

    let derivationPath: String

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.derivationPath)
                    .font(uiFont: UIFont.font(of: .text3, weight: .semibold))
                    .foregroundColor(Color(.night))

                Text(derivationPath)
                    .apply(style: .label1)
                    .foregroundColor(Color(.mountain))
            }

            Spacer()

            Image(.chevronRight)
                .renderingMode(.template)
                .foregroundColor(Color(.mountain))
                .frame(width: 20, height: 25)
                .scaledToFill()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 28)
        .background(Color(.snow))
        .addBorder(Color(.rain), cornerRadius: 16)
        .shadow(color: .black.opacity(0.05), radius: 8 / UIScreen.main.scale)
    }
}
