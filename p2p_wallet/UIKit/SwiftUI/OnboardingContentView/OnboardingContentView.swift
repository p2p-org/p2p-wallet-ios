import KeyAppUI
import SwiftUI

struct OnboardingContentView: View {
    let data: OnboardingContentData
    let maxWidth: CGFloat

    init(data: OnboardingContentData, maxWidth: CGFloat = 300) {
        self.data = data
        self.maxWidth = maxWidth
    }

    var body: some View {
        VStack(spacing: .zero) {
            Image(uiImage: data.image)
                .resizable()
                .scaledToFit()
                .frame(
                    minWidth: 128,
                    maxWidth: maxWidth
                )
            Text(data.title)
                .font(.system(size: UIFont.fontSize(of: .largeTitle), weight: .bold))
                .foregroundColor(Color(Asset.Colors.night.color))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)

            VStack(spacing: .zero) {
                ForEach(data.subtitles) { subtitle in
                    if subtitle.isLimited {
                        Text(subtitle.text)
                            .subtitleStyle()
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .minimumScaleFactor(UIFont.fontSize(of: .text2) / UIFont.fontSize(of: .title3))
                    } else {
                        Text(subtitle.text)
                            .subtitleStyle()
                    }
                }
            }
            .padding(.top, 16)
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
