import SwiftUI
import KeyAppUI

struct StrigaRegistrationTextField: View {

    let field: StrigaRegistrationField
    let placeholder: String
    let isEnabled: Bool
    let onSubmit: () -> Void
    let submitLabel: SubmitLabel

    @Binding var text: String
    @Binding var focus: StrigaRegistrationField?

    @FocusState private var isFocused: StrigaRegistrationField?

    init(
        field: StrigaRegistrationField,
        placeholder: String,
        text: Binding<String>,
        isEnabled: Bool = true,
        focus: Binding<StrigaRegistrationField?>,
        onSubmit: @escaping () -> Void,
        submitLabel: SubmitLabel
    ) {
        self.field = field
        self.placeholder = placeholder
        self._text = text
        self.isEnabled = isEnabled
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
            .font(uiFont: .font(of: .title2))
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
        }
    }
}

struct StrigaRegistrationTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StrigaRegistrationTextField(
                field: .email,
                placeholder: "Enter email",
                text: .constant(""),
                focus: .constant(nil),
                onSubmit: { },
                submitLabel: .next
            )

            StrigaRegistrationTextField(
                field: .phoneNumber,
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
