import SwiftUI
import KeyAppUI

struct StrigaRegistrationTextField: View {
    let placeholder: String
    @Binding var text: String
    let isEnabled: Bool
    let maxSymbolsLimit: Int?

    init(
        placeholder: String,
        text: Binding<String>,
        isEnabled: Bool = true,
        maxSymbolsLimit: Int? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isEnabled = isEnabled
        self.maxSymbolsLimit = maxSymbolsLimit
    }

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: maxSymbolsLimit == nil ? $text : $text.max(maxSymbolsLimit!))
                .font(uiFont: .font(of: .title2))
                .foregroundColor(isEnabled ? Color(asset: Asset.Colors.night) : Color(asset: Asset.Colors.night).opacity(0.3))
                .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 20))
                .frame(height: 56)
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

private extension Binding where Value == String {
    func max(_ limit: Int) -> Self {
        if self.wrappedValue.count > limit {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.dropLast())
            }
        }
        return self
    }
}
