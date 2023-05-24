import SwiftUI
import KeyAppUI

struct StrigaRegistrationTextField: View {
    let title: String
    let placeholder: String
    let isDetailed: Bool
    @Binding var text: String
    let isInvalid: Bool

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isDetailed: Bool = false,
        isInvalid: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self.isDetailed = isDetailed
        self._text = text
        self.isInvalid = isInvalid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 8)
                Text(title)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .apply(style: .label1)
            }

            HStack(spacing: 12) {
                TextField(placeholder, text: $text)
                    .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 20))
                    .frame(height: 56)

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
                    .stroke(isInvalid ? Color(asset: Asset.Colors.rose) : .clear, lineWidth: 1)
            )

            if isInvalid {
                Text(L10n.couldNotBeEmpty)
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
                isInvalid: true
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
