import SwiftUI
import KeyAppUI

struct StrigaRegistrationDateTextField: View {

    private let charLimit : Int = 10
    @State private var text: String = ""
    @Binding private var underlyingString: String

    init(text: Binding<String>) {
        _underlyingString = text
    }

    var body: some View {
        TextField(L10n.Dd.Mm.yyyy, text: $text, onCommit: updateUnderlyingValue)
            .font(uiFont: .font(of: .title2))
            .foregroundColor(Color(asset: Asset.Colors.night))
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 20))
            .frame(height: 56)
            .keyboardType(.numberPad)
            .onAppear(perform: { updateEnteredString(newUnderlyingString: underlyingString) })
            .onChange(of: text, perform: updateUndelyingString)
            .onChange(of: underlyingString, perform: updateEnteredString)
    }

    func updateEnteredString(newUnderlyingString: String) {
        text = String(newUnderlyingString.prefix(charLimit))
    }

    func updateUndelyingString(newEnteredString: String) {
        if newEnteredString.count > charLimit {
            self.text = String(newEnteredString.prefix(charLimit))
        } else if newEnteredString.count < underlyingString.count {
            if newEnteredString.count == 2 || newEnteredString.count == 5 {
                self.text = String(newEnteredString.dropLast(1))
            } else {
                self.text = newEnteredString
            }
        } else if newEnteredString.count == 2 {
            self.text = newEnteredString.appending(".")
        } else if newEnteredString.count == 5 {
            self.text = newEnteredString.appending(".")
        }
        underlyingString = self.text
    }

    func updateUnderlyingValue() {
        underlyingString = text
    }
}

struct StrigaRegistrationDateTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StrigaRegistrationDateTextField(text: .constant(""))
        }
        .padding(16)
        .background(Color(asset: Asset.Colors.sea))
    }
}
