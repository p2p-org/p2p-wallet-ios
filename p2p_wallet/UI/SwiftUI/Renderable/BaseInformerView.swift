import SwiftUI
import KeyAppUI

struct BaseInformerViewItem: Identifiable {
    enum Title {
        case plain(String)
        case attributed(NSAttributedString)
    }

    var id = UUID().uuidString

    let icon: UIImage
    let iconColor: ColorAsset
    let title: Title
    let backgroundColor: ColorAsset
    let iconBackgroundColor: ColorAsset
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

            switch data.title {
            case .plain(let text):
                Text(text)
                    .apply(style: .text4)
                    .foregroundColor(Color(asset: Asset.Colors.night))
            case .attributed(let text):
                Text(text)
            }

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
            title: .plain(L10n.EnterYourPersonalDataToOpenAnAccount.pleaseUseYourRealCredentials),
            backgroundColor: Asset.Colors.lightSea,
            iconBackgroundColor: Asset.Colors.sea
        ))
    }
}
