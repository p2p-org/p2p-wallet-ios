import SwiftUI
import KeyAppUI

struct StrigaRegistrationDateTextField: View {

    private let status: StrigaRegistrationTextFieldStatus
    private let charLimit : Int = 10

    @State private var text: String = ""
    @Binding private var underlyingString: String

    init(
        text: Binding<String>,
        status: StrigaRegistrationTextFieldStatus? = .valid
    ) {
        self.status = status ?? .valid
        _underlyingString = text
    }

    @State var input: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.dateOfBirth)
                .foregroundColor(Color(asset: Asset.Colors.mountain))
                .apply(style: .label1)
                .padding(.leading, 8)

            HStack(spacing: 12) {
                TextField(L10n.Dd.Mm.yyyy, text: $text, onCommit: updateUnderlyingValue)
                    .foregroundColor(Color(asset: Asset.Colors.night))
                    .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 20))
                    .frame(height: 56)
                    .keyboardType(.numberPad)
                    .onAppear(perform: { updateEnteredString(newUnderlyingString: underlyingString) })
                    .onChange(of: text, perform: updateUndelyingString)
                    .onChange(of: underlyingString, perform: updateEnteredString)
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
            StrigaRegistrationDateTextField(
                text: .constant("")
            )
        }
        .padding(16)
        .background(Color(asset: Asset.Colors.sea))
    }
}
