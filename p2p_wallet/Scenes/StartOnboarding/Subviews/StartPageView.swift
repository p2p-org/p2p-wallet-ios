import KeyAppUI
import SwiftUI

struct StartPageView: View {
    @State var data: StartPageData

    let subtitleFontWeight: SwiftUI.Font.Weight

    var body: some View {
        VStack(spacing: .zero) {
            Image(uiImage: data.image)
                .resizable()
                .scaledToFit()
                .frame(minWidth: 200, maxWidth: 300, minHeight: 150, maxHeight: 224)

            Text(data.title)
                .font(.system(size: UIFont.fontSize(of: .largeTitle), weight: .bold))
                .foregroundColor(Color(Asset.Colors.night.color))
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            Text(data.subtitle)
                .font(.system(size: UIFont.fontSize(of: .title3), weight: subtitleFontWeight))
                .foregroundColor(Color(Asset.Colors.night.color))
                .multilineTextAlignment(.center)
                .padding(.top, 16)
        }
    }
}
