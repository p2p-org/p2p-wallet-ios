import SwiftUI
import KeyAppUI

struct StrigaRegistrationInfoViewModel {
    let icon: UIImage
    let iconColor: ColorAsset
    let title: String
    let backgroundColor: ColorAsset
    let iconBackgroundColor: ColorAsset

    static let credentials = StrigaRegistrationInfoViewModel(
        icon: .infoFill,
        iconColor: Asset.Colors.snow,
        title: L10n.EnterYourPersonalDataToOpenAnAccount.pleaseUseYourRealCredentials,
        backgroundColor: Asset.Colors.lightSea,
        iconBackgroundColor: Asset.Colors.sea
    )

    static let confirm = StrigaRegistrationInfoViewModel(
        icon: .shieldSmall,
        iconColor: Asset.Colors.night,
        title: L10n.afterClickingTheСontinueYouConfirmThatYouAreNotAPoliticallyExposedPerson,
        backgroundColor: Asset.Colors.rain,
        iconBackgroundColor: Asset.Colors.smoke
    )
}

struct StrigaRegistrationInfoView: View {
    let appearance: StrigaRegistrationInfoViewModel

    var body: some View {
        HStack(spacing: 17) {
            Circle()
                .fill(Color(asset: appearance.iconBackgroundColor))
                .frame(width: 49, height: 49)
                .overlay(
                    Image(uiImage: appearance.icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fill)
                        .foregroundColor(Color(asset: appearance.iconColor))
                        .frame(width: 20, height: 20)
                )

            Text(appearance.title)
                .apply(style: .text4)
                .foregroundColor(Color(asset: Asset.Colors.night))

            Spacer()
        }
        .padding(.all, 17)
        .background(Color(asset: appearance.backgroundColor))
        .cornerRadius(radius: 12, corners: .allCorners)
    }
}

struct StrigaRegistrationInformerView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaRegistrationInfoView(appearance: .credentials)
    }
}
