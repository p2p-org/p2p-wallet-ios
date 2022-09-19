import KeyAppUI
import SwiftUI

struct OnboardingContentView: View {
    let data: OnboardingContentData

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

            if data.email != nil || data.subtitle != nil {
                VStack(spacing: .zero) {
                    if let email = data.email {
                        Text(email)
                            .subtitleStyle()
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .minimumScaleFactor(UIFont.fontSize(of: .text2) / UIFont.fontSize(of: .title3))
                    }
                    if let subtitle = data.subtitle {
                        Text(subtitle)
                            .subtitleStyle()
                    }
                }
                .padding(.top, 16)
            }
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
