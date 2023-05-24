import SwiftUI
import KeyAppUI

enum StrigaRegistrationTextFieldStatus: Equatable {
    case valid
    case invalid(error: String)
}

struct StrigaRegistrationTextField: View {
    let title: String
    let placeholder: String
    let isDetailed: Bool
    @Binding var text: String
    let status: StrigaRegistrationTextFieldStatus
    let isEnabled: Bool
    let maxSymbolsLimit: Int?

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        status: StrigaRegistrationTextFieldStatus? = .valid,
        isDetailed: Bool = false,
        isEnabled: Bool = true,
        maxSymbolsLimit: Int? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self.isDetailed = isDetailed
        self.status = status ?? .valid
        self._text = text
        self.isEnabled = isEnabled
        self.maxSymbolsLimit = maxSymbolsLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundColor(Color(asset: Asset.Colors.mountain))
                .apply(style: .label1)
                .padding(.leading, 8)

            HStack(spacing: 12) {
                TextField(placeholder, text: $text)
                    .foregroundColor(isEnabled ? Color(asset: Asset.Colors.night) : Color(asset: Asset.Colors.night).opacity(0.3))
                    .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 20))
                    .frame(height: 56)
                    .disabled(isDetailed)

                if isDetailed {
                    Image(asset: Asset.MaterialIcon.chevronRight)
                        .renderingMode(.template)
                        .foregroundColor(Color(asset: Asset.Colors.silver))
                        .padding(.trailing, 16)
                }
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

struct StrigaRegistrationTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StrigaRegistrationTextField(
                title: "Email",
                placeholder: "Enter email",
                text: .constant("")
            )

            StrigaRegistrationTextField(
                title: "Phone",
                placeholder: "Enter phone",
                text: .constant(""),
                status: .invalid(error: L10n.couldNotBeEmpty)
            )

            StrigaRegistrationTextField(
                title: "Country",
                placeholder: "Select country",
                text: .constant(""),
                isDetailed: true
            )
        }
        .padding(16)
        .background(Color(asset: Asset.Colors.sea))
    }
}
