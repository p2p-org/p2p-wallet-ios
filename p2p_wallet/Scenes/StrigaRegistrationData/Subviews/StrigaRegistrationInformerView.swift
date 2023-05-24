import SwiftUI
import KeyAppUI

struct StrigaRegistrationInformerView: View {
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(Asset.Colors.sea.color))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(uiImage: .infoFill)
                        .renderingMode(.template)
                        .foregroundColor(Color(Asset.Colors.snow.color))
                )

            Text(L10n.EnterYourPersonalDataToOpenAnAccount.pleaseUseYourRealCredentials)
                .apply(style: .text4)
                .foregroundColor(Color(Asset.Colors.night.color))
        }
        .padding(.all, 16)
        .background(Color(Asset.Colors.lightSea.color))
        .cornerRadius(radius: 12, corners: .allCorners)
    }
}

struct StrigaRegistrationInformerView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaRegistrationInformerView()
    }
}
