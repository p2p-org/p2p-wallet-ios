import SwiftUI
import KeyAppUI

struct StrigaRegistrationDetailedButton: View {
    @Binding private var value: String
    private let action: () -> Void

    init(value: Binding<String>, action: @escaping () -> Void) {
        self._value = value
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(value.isEmpty ? L10n.selectFromList : value)
                    .apply(style: .title2)
                    .foregroundColor(Color(asset: Asset.Colors.night))
                Spacer()
                Image(asset: Asset.MaterialIcon.chevronRight)
                    .renderingMode(.template)
                    .foregroundColor(Color(asset: Asset.Colors.night))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}
