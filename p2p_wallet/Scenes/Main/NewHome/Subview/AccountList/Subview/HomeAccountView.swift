import KeyAppUI
import SwiftUI
import Kingfisher

struct HomeAccountView: View {
    let iconSize: CGFloat = 48
    let rendable: any RenderableAccount

    let onTap: (() -> Void)?
    let onButtonTap: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            switch rendable.icon {
            case let .url(url):
                KFImage
                    .url(url)
                    .setProcessor(
                        DownsamplingImageProcessor(size: .init(width: iconSize*3, height: iconSize*3))
                            |> RoundCornerImageProcessor(cornerRadius: iconSize)
                    )
                    .resizable()
                    .diskCacheExpiration(.days(7))
                    .fade(duration: 0.25)
                    .frame(width: iconSize, height:  iconSize)
            case let .image(image):
                CoinLogoImageViewRepresentable(
                    size: iconSize,
                    args: .manual(preferredImage: image, url: nil, key: "", wrapped: rendable.wrapped)
                )
                .frame(width: iconSize, height: iconSize)
            case let .random(seed):
                CoinLogoImageViewRepresentable(
                    size: iconSize,
                    args: .manual(preferredImage: nil, url: nil, key: seed, wrapped: rendable.wrapped)
                )
                .frame(width: iconSize, height: iconSize)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(rendable.title)
                    .font(uiFont: .font(of: .text2))
                    .foregroundColor(Color(Asset.Colors.night.color))
                Text(rendable.subtitle)
                    .font(uiFont: .font(of: .label1))
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()

            switch rendable.detail {
            case let .text(text):
                Text(text)
                    .font(uiFont: .font(of: .text3, weight: .semibold))
                    .foregroundColor(Color(Asset.Colors.night.color))
            case let .button(text, enabled):
                Button(
                    action: { onButtonTap?() },
                    label: {
                        Text(text)
                            .padding(.horizontal, 12)
                            .font(uiFont: TextButton.Style.second.font(size: .small))
                            .foregroundColor(Color(
                                enabled ? TextButton.Style.primaryWhite.foreground
                                    : TextButton.Style.primaryWhite.disabledForegroundColor!
                            ))
                            .frame(height: TextButton.Size.small.height)
                            .background(Color(
                                enabled ? TextButton.Style.primaryWhite.backgroundColor
                                    : TextButton.Style.primaryWhite.disabledBackgroundColor!
                            ))
                            .cornerRadius(12)
                    }
                )
            }
        }
        .contentShape(Rectangle())
        .if(rendable.onTapEnable) { view in
            view.onTapGesture {
                onTap?()
            }
        }
    }
}

struct HomeAccountView_Previews: PreviewProvider {
    static var previews: some View {
        HomeAccountView(
            rendable: RendableMockAccount(
                id: "123",
                icon: .image(.solanaIcon),
                wrapped: true,
                title: "Solana",
                subtitle: "0.1747 SOL",
                detail: .text("$ 3.67"),
                extraAction: .visiable,
                tags: []
            )
        ) {} onButtonTap: {}
    }
}
