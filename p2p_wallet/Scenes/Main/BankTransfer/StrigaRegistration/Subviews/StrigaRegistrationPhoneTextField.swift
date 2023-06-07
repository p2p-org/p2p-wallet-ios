import SwiftUI
import KeyAppUI
import PhoneNumberKit
import CountriesAPI

struct StrigaRegistrationPhoneTextField: View {

    @Binding private var trackedText: String
    @Binding private var phoneNumber: PhoneNumber?
    @Binding private var country: Country?

    @State private var text: String = ""
    @State private var underlyingString: String = ""
    private let phoneNumberKit: PhoneNumberKit
    private let action: () -> Void
    private let partialFormatter: PartialFormatter

    init(
        text: Binding<String>,
        phoneNumber: Binding<PhoneNumber?>,
        country: Binding<Country?>,
        action: @escaping () -> Void
    ) {
        _trackedText = text
        underlyingString = text.wrappedValue
        _phoneNumber = phoneNumber
        _country = country
        let numberKit = PhoneNumberKit()
        self.phoneNumberKit = numberKit
        self.partialFormatter = PartialFormatter(phoneNumberKit: numberKit, withPrefix: true)
        self.action = action
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: action) {
                HStack(spacing: 6) {
                    Text(country?.emoji ?? "🏴")
                        .font(uiFont: .font(of: .title1, weight: .bold))
                    Image(uiImage: .expandIcon)
                        .renderingMode(.template)
                        .foregroundColor(Color(asset: Asset.Colors.night))
                        .frame(width: 8, height: 5)
                }
            }

            HStack(spacing: 4) {
                Text(country?.dialCode ?? "")
                    .apply(style: .title2)
                    .foregroundColor(Color(asset: Asset.Colors.night))

                TextField(L10n.enter, text: $text, onCommit: updateUnderlyingValue)
                    .font(uiFont: .font(of: .title2))
                    .foregroundColor(Color(asset: Asset.Colors.night))
                    .keyboardType(.numberPad)
                    .onAppear(perform: { updateEnteredString(newUnderlyingString: underlyingString) })
                    .onChange(of: text, perform: updateUndelyingString)
                    .onChange(of: underlyingString, perform: updateEnteredString)

                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(uiImage: .closeIcon)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color(asset: Asset.Colors.night))
                            .frame(width: 14, height: 14)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 20))
        .frame(height: 56)
    }

    private func updateEnteredString(newUnderlyingString: String) {
        text = newUnderlyingString
    }

    private func updateUndelyingString(newEnteredString: String) {
        var newText = newEnteredString
        if let code = country?.dialCode, let examplePhoneNumber = self.exampleNumberWith(
            phone: "+\(code)\(text.replacingOccurrences(of: " ", with: ""))"
        ) {
            let formattedExample = phoneNumberKit.format(examplePhoneNumber, toType: .international, withPrefix: false)
                .replacingOccurrences(of: "[0-9]", with: "X", options: .regularExpression)
                .replacingOccurrences(of: "-", with: " ")
                .appending("XXXXX")
            newText = format(with: formattedExample, phone: newEnteredString)
            self.phoneNumber = try? phoneNumberKit.parse("+\(code)\(text.replacingOccurrences(of: " ", with: ""))")
        } else {
            self.phoneNumber = nil
        }
        self.text = newText
        trackedText = self.text
    }

    private func updateUnderlyingValue() {
        underlyingString = text
    }

    private func exampleNumberWith(phone: String? = "") -> PhoneNumber? {
        _ = partialFormatter.nationalNumber(from: phone ?? "")
        let country = partialFormatter.currentRegion
        return phoneNumberKit.getExampleNumber(forCountry: country)
    }

    private func format(with mask: String, phone: String) -> String {
        if phone == "+" { return phone }
        let numbers = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        var result = ""
        var index = numbers.startIndex // numbers iterator

        // iterate over the mask characters until the iterator of numbers ends
        for ch in mask where index < numbers.endIndex {
            if ch == "X" {
                // mask requires a number in this place, so take the next one
                result.append(numbers[index])

                // move numbers iterator to the next index
                index = numbers.index(after: index)

            } else {
                result.append(ch) // just append a mask character
            }
        }
        return result
    }
}
