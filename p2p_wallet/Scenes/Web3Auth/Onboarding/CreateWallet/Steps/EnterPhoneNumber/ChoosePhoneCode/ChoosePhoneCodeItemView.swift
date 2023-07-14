import KeyAppUI
import SwiftUI

struct ChoosePhoneCodeItemView: View {
    let emoji: String
    let countryName: String
    let phoneCode: String
    let isSelected: Bool

    init(country: SelectableCountry) {
        self.emoji = country.value.emoji ?? ""
        self.countryName = country.value.name
        self.phoneCode = country.value.dialCode
        self.isSelected = country.isSelected
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .frame(width: 28, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(countryName)
                    .apply(style: .text3)
                    .foregroundColor(Color(.night))
                    .lineLimit(2)

                if !phoneCode.isEmpty {
                    Text(phoneCode)
                        .apply(style: .label1)
                        .foregroundColor(Color(.mountain))
                        .lineLimit(1)
                }
            }
            Spacer()
            if isSelected {
                Image(.checkmarkBlueOriginal)
                    .frame(width: 14.3, height: 14.19)
            }
            
        }
        .padding(14)
        .background(Color(.snow))
    }
}
