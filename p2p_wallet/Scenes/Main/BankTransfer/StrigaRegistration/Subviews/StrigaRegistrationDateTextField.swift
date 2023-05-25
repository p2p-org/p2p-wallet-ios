import SwiftUI
import KeyAppUI

struct StrigaRegistrationDateTextField: View {
    @Binding var text: String
    let status: StrigaRegistrationTextFieldStatus

    init(
        text: Binding<String>,
        status: StrigaRegistrationTextFieldStatus? = .valid
    ) {
        self.status = status ?? .valid
        self._text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.dateOfBirth)
                .foregroundColor(Color(asset: Asset.Colors.mountain))
                .apply(style: .label1)
                .padding(.leading, 8)

            HStack(spacing: 12) {
                TextField(L10n.Dd.Mm.yyyy, text: $text.max(8))
                    .foregroundColor(Color(asset: Asset.Colors.night))
                    .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 20))
                    .frame(height: 56)
                    .keyboardType(.numberPad)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(asset: Asset.Colors.snow))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(status == .valid ? .clear : Color(asset: Asset.Colors.rose), lineWidth: 1)
            )

            if case .invalid(let error) = status {
                Text(error)
                    .apply(style: .label1)
                    .foregroundColor(Color(asset: Asset.Colors.rose))
            }
        }
    }
}

struct StrigaRegistrationDateTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StrigaRegistrationDateTextField(
                text: .constant("")
            )
        }
        .padding(16)
        .background(Color(asset: Asset.Colors.sea))
    }
}

extension Binding where Value == String {
    func max(_ limit: Int) -> Self {
        if self.wrappedValue.count > limit {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.dropLast())
            }
        }
        return self
    }
}
