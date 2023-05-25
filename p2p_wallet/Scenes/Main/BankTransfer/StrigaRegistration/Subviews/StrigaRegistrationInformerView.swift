import SwiftUI
import KeyAppUI

struct StrigaRegistrationInformerView: View {
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(asset: Asset.Colors.sea))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(uiImage: .infoFill)
                        .renderingMode(.template)
                        .foregroundColor(Color(asset: Asset.Colors.snow))
                )

            Text(L10n.EnterYourPersonalDataToOpenAnAccount.pleaseUseYourRealCredentials)
                .apply(style: .text4)
                .foregroundColor(Color(asset: Asset.Colors.night))
        }
        .padding(.all, 16)
        .background(Color(asset: Asset.Colors.lightSea))
        .cornerRadius(radius: 12, corners: .allCorners)
    }
}

struct StrigaRegistrationInformerView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaRegistrationInformerView()
    }
}
