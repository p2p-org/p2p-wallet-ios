import KeyAppUI
import SwiftUI

struct SolendTutorialSlideView: View {
    let data: SolendTutorialContentData

    var body: some View {
        VStack(spacing: .zero) {
            Image(uiImage: data.image)
                .resizable()
                .scaledToFit()
                .frame(
                    minWidth: 128,
                    maxWidth: 300,
                    minHeight: 96,
                    maxHeight: 224
                )
            Text(data.title)
                .font(.system(size: UIFont.fontSize(of: .largeTitle), weight: .bold))
                .foregroundColor(Color(Asset.Colors.night.color))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)
                .padding(.horizontal)

            Text(data.subtitle)
                .subtitleStyle()
                .padding(.top, 16)
                .padding(.horizontal)
        }
    }
}

private extension Text {
    func subtitleStyle() -> some View {
        font(.system(size: UIFont.fontSize(of: .title3), weight: .regular))
            .foregroundColor(Color(Asset.Colors.night.color))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
