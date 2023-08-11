import CountriesAPI
import KeyAppUI
import PhoneNumberKit
import SwiftUI

struct StrigaRegistrationPhoneTextField: View {
    private let field = StrigaRegistrationField.phoneNumber

    @Binding private var trackedText: String
    @Binding private var phoneNumber: PhoneNumber?
    @Binding private var country: Country?

    @State private var text: String = ""
    @State private var underlyingString: String = ""

    private let phoneNumberKit: PhoneNumberKit
    private let countryTapped: () -> Void
    private let partialFormatter: PartialFormatter

    @Binding private var focus: StrigaRegistrationField?
    @FocusState private var isFocused: StrigaRegistrationField?

    init(
        text: Binding<String>,
        phoneNumber: Binding<PhoneNumber?>,
        country: Binding<Country?>,
        countryTapped: @escaping () -> Void,
        focus: Binding<StrigaRegistrationField?>
    ) {
        _focus = focus
        _trackedText = text
        underlyingString = text.wrappedValue
        _phoneNumber = phoneNumber
        _country = country
        let numberKit = PhoneNumberKit()
        phoneNumberKit = numberKit
        partialFormatter = PartialFormatter(phoneNumberKit: numberKit, withPrefix: true)
        self.countryTapped = countryTapped
    }

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Text(country?.emoji ?? "🏴")
                    .fontWeight(.bold)
                    .apply(style: .title1)
                Image(uiImage: .expandIcon)
                    .renderingMode(.template)
                    .foregroundColor(Color(asset: Asset.Colors.night))
                    .frame(width: 8, height: 5)
            }.onTapGesture {
                countryTapped()
            }

            HStack(spacing: 4) {
                Text(country?.dialCode ?? "")
                    .apply(style: .title2)
                    .foregroundColor(Color(asset: Asset.Colors.night))

                TextField(
                    L10n.enter,
                    text: $text,
                    onEditingChanged: { changed in
                        if changed {
                            focus = field
                        } else {
                            updateUnderlyingValue() // updating value on unfocus
                        }
                    },
                    onCommit: updateUnderlyingValue
                )
                .font(uiFont: .font(of: .title2))
                .foregroundColor(Color(asset: Asset.Colors.night))
                .keyboardType(.numberPad)
                .onAppear(perform: { updateEnteredString(newUnderlyingString: underlyingString) })
                .onChange(of: text, perform: updateUndelyingString)
                .onChange(of: underlyingString, perform: updateEnteredString)
                .onChange(of: focus, perform: { newValue in
                    self.isFocused = newValue
                })
                .focused(self.$isFocused, equals: field)

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
        if let code = country?.dialCode, let examplePhoneNumber = exampleNumberWith(
            phone: "+\(code)\(text.replacingOccurrences(of: " ", with: ""))"
        ) {
            let formattedExample = phoneNumberKit.format(examplePhoneNumber, toType: .international, withPrefix: false)
                .replacingOccurrences(of: "[0-9]", with: "X", options: .regularExpression)
                .replacingOccurrences(of: "-", with: " ")
                .appending("XXXXX")
            newText = format(with: formattedExample, phone: newEnteredString)
            phoneNumber = try? phoneNumberKit.parse("+\(code)\(text.replacingOccurrences(of: " ", with: ""))")
        } else {
            phoneNumber = nil
        }
        text = newText
        trackedText = text
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
