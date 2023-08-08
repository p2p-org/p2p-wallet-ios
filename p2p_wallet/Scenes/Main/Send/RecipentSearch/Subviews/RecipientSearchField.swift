import KeyAppUI
import SwiftUI

struct RecipientSearchField: View {
    @Binding var text: String
    @Binding var isLoading: Bool
    @Binding var isFirstResponder: Bool

    let past: () -> Void
    let scan: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            HStack {
                FocusedTextField(text: $text, isFirstResponder: $isFirstResponder) { textField in
                    textField.placeholder = L10n.usernameOrAddress
                    textField.autocapitalizationType = .none
                    textField.autocorrectionType = .no
                    textField.spellCheckingType = .no
                    textField.returnKeyType = .done
                    textField.keyboardType = .asciiCapable
                    textField.textContentType = .oneTimeCode
                    textField.clearButtonMode = .never
                }
                .frame(height: 24)
                    .padding(.vertical, 12)
                    .accessibilityIdentifier("RecipientSearchField.FocusedTextField")

                if isLoading {
                    Spinner()
                        .frame(width: 12, height: 12)
                } else if text.isEmpty {
                    Button { past() }
                        label: {
                            Image(uiImage: Asset.Icons.past.image)
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(Color(Asset.Colors.night.color))
                        }
                            .accessibilityIdentifier("RecipientSearchField.paste")
                } else {
                    Button { text = "" }
                        label: {
                            Image(uiImage: .crossIcon)
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(Color(Asset.Colors.night.color))
                        }
                        .accessibilityIdentifier("RecipientSearchField.clear")
                }
            }
            .padding(.horizontal, 18)
            .background(
                Color(Asset.Colors.rain.color)
                    .cornerRadius(radius: 12, corners: .allCorners)
            )

            Button {
                scan()
            } label: {
                ZStack {
                    Image(uiImage: Asset.Icons.qr.image)
                        .resizable()
                        .frame(width: 18, height: 18)
                        .foregroundColor(Color(Asset.Colors.night.color))
                    Rectangle()
                        .frame(width: 30, height: 30)
                        .opacity(0)
                }
            }
            .padding(EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 0))
            .accessibilityIdentifier("RecipientSearchField.qr")
        }
    }
}

struct RecipientSearchField_Previews: PreviewProvider {
    static var previews: some View {
        RecipientSearchField(
            text: .constant("Hello"),
            isLoading: .constant(false),
            isFirstResponder: .constant(false)
        ) {} scan: {}
    }
}
