import SwiftUI
import KeyAppUI

struct StrigaRegistrationTextField: View {
    let placeholder: String
    @Binding var text: String
    let isEnabled: Bool

    init(
        placeholder: String,
        text: Binding<String>,
        isEnabled: Bool = true
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isEnabled = isEnabled
    }

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $text)
                .font(uiFont: .font(of: .title2))
                .foregroundColor(isEnabled ? Color(asset: Asset.Colors.night) : Color(asset: Asset.Colors.night).opacity(0.3))
                .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 20))
                .frame(height: 58)
                .disabled(!isEnabled)
        }
    }
}

struct StrigaRegistrationTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StrigaRegistrationTextField(
                placeholder: "Enter email",
                text: .constant("")
            )

            StrigaRegistrationTextField(
                placeholder: "Enter phone",
                text: .constant("")
            )

            StrigaRegistrationTextField(
                placeholder: "Select country",
                text: .constant("")
            )
        }
        .padding(16)
        .background(Color(asset: Asset.Colors.sea))
    }
}
