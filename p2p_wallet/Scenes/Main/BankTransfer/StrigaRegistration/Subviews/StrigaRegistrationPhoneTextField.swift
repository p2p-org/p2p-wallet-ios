import SwiftUI
import KeyAppUI
import PhoneNumberKit

struct StrigaRegistrationPhoneTextField: View {

    private let charLimit: Int = 15
    @State private var text: String = ""
    @Binding private var underlyingString: String
    @Binding private var phoneNumber: PhoneNumber?

    private let phoneNumberKit = PhoneNumberKit()

    init(text: Binding<String>, phoneNumber: Binding<PhoneNumber?>) {
        _underlyingString = text
        _phoneNumber = phoneNumber
    }

    var body: some View {
        HStack(spacing: 2) {
            Text("+")
                .apply(style: .title2)
                .foregroundColor(Color(asset: Asset.Colors.night))

            TextField(L10n.enter, text: $text, onCommit: updateUnderlyingValue)
                .font(uiFont: .font(of: .title2))
                .foregroundColor(Color(asset: Asset.Colors.night))
                .keyboardType(.numberPad)
                .onAppear(perform: { updateEnteredString(newUnderlyingString: underlyingString) })
                .onChange(of: text, perform: updateUndelyingString)
                .onChange(of: underlyingString, perform: updateEnteredString)
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 20))
        .frame(height: 56)
    }

    func updateEnteredString(newUnderlyingString: String) {
        text = String(newUnderlyingString.prefix(charLimit))
    }

    func updateUndelyingString(newEnteredString: String) {
        var newText = newEnteredString
        if let phoneNumber = try? phoneNumberKit.parse(newEnteredString) {
            newText = phoneNumberKit.format(phoneNumber, toType: .international)
                .replacingOccurrences(of: "+", with: "")
                .replacingOccurrences(of: "-", with: " ")
            self.phoneNumber = phoneNumber
        } else {
            self.phoneNumber = nil
        }
        self.text = newText
    }

    func updateUnderlyingValue() {
        underlyingString = text
    }
}
