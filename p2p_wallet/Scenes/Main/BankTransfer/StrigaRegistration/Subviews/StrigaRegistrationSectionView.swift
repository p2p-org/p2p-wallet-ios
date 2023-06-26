import SwiftUI
import KeyAppUI

struct StrigaRegistrationSectionView: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text(title.uppercased())
                .apply(style: .caps)
                .foregroundColor(Color(Asset.Colors.night.color))
        }
        .frame(minHeight: 33)
    }
}
