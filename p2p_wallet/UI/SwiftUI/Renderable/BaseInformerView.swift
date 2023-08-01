import KeyAppUI
import SwiftUI

struct BaseInformerViewItem: Identifiable {
    let id = UUID().uuidString

    let icon: UIImage
    let iconColor: ColorAsset
    let title: String
    let titleColor: ColorAsset
    let backgroundColor: ColorAsset
    let iconBackgroundColor: ColorAsset

    init(
        icon: UIImage,
        iconColor: ColorAsset,
        title: String,
        titleColor: ColorAsset = Asset.Colors.night,
        backgroundColor: ColorAsset,
        iconBackgroundColor: ColorAsset
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.iconBackgroundColor = iconBackgroundColor
    }
}

// MARK: - Renderable

extension BaseInformerViewItem: Renderable {
    func render() -> some View {
        BaseInformerView(data: self)
    }
}

// MARK: - View

struct BaseInformerView: View {
    let data: BaseInformerViewItem

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(asset: data.iconBackgroundColor))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(uiImage: data.icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fill)
                        .foregroundColor(Color(asset: data.iconColor))
                        .frame(width: 20, height: 20)
                )

            Text(data.title)
                .apply(style: .text4)
                .foregroundColor(Color(asset: data.titleColor))

            Spacer()
        }
        .padding(.all, 17)
        .background(Color(asset: data.backgroundColor))
        .cornerRadius(radius: 12, corners: .allCorners)
    }
}

struct BaseInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BaseInformerView(data: BaseInformerViewItem(
            icon: .infoFill,
            iconColor: Asset.Colors.snow,
            title: L10n.EnterYourPersonalDataToOpenAnAccount.pleaseUseYourRealCredentials,
            backgroundColor: Asset.Colors.lightSea,
            iconBackgroundColor: Asset.Colors.sea
        ))
    }
}
