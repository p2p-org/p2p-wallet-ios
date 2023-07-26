import SwiftUI
import KeyAppUI

struct StrigaRegistrationTextField<TextFieldType: Identifiable & Hashable>: View {

    let field: TextFieldType
    let fontStyle: UIFont.Style
    let placeholder: String
    let isEnabled: Bool
    let onSubmit: () -> Void
    let submitLabel: SubmitLabel
    let showClearButton: Bool

    @Binding var text: String
    @Binding var focus: TextFieldType?

    @FocusState private var isFocused: TextFieldType?

    init(
        field: TextFieldType,
        fontStyle: UIFont.Style = .title2,
        placeholder: String,
        text: Binding<String>,
        isEnabled: Bool = true,
        showClearButton: Bool = false,
        focus: Binding<TextFieldType?>,
        onSubmit: @escaping () -> Void,
        submitLabel: SubmitLabel
    ) {
        self.field = field
        self.fontStyle = fontStyle
        self.placeholder = placeholder
        self._text = text
        self.isEnabled = isEnabled
        self.showClearButton = showClearButton
        self._focus = focus
        self.onSubmit = onSubmit
        self.submitLabel = submitLabel
    }

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $text, onEditingChanged: { editing in
                guard editing else { return }
                focus = field
            })
            .font(uiFont: .font(of: fontStyle))
            .foregroundColor(isEnabled ? Color(asset: Asset.Colors.night) : Color(asset: Asset.Colors.night).opacity(0.3))
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 20))
            .frame(height: 58)
            .disabled(!isEnabled)
            .onChange(of: focus, perform: { newValue in
                self.isFocused = newValue
            })
            .focused(self.$isFocused, equals: field)
            .submitLabel(submitLabel)
            .onSubmit {
                self.onSubmit()
            }

            if showClearButton, !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(uiImage: .closeIcon)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(asset: Asset.Colors.night))
                        .frame(width: 16, height: 16)
                }.padding(.trailing, 16)
            }
        }
    }
}

struct StrigaRegistrationTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StrigaRegistrationTextField<StrigaRegistrationField>(
                field: StrigaRegistrationField.email,
                placeholder: "Enter email",
                text: .constant(""),
                focus: .constant(nil),
                onSubmit: { },
                submitLabel: .next
            )

            StrigaRegistrationTextField<StrigaRegistrationField>(
                field: StrigaRegistrationField.phoneNumber,
                placeholder: "Enter phone",
                text: .constant(""),
                focus: .constant(nil),
                onSubmit: { },
                submitLabel: .done
            )
        }
        .padding(16)
        .background(Color(asset: Asset.Colors.sea))
    }
}
