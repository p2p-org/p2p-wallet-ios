import KeyAppUI
import SwiftUI

struct CryptoAccountCellView: View, Equatable {
    let iconSize: CGFloat = 50
    let rendable: any RenderableAccount

    let onTap: (() -> Void)?
    let onButtonTap: (() -> Void)?

    static func == (lhs: CryptoAccountCellView, rhs: CryptoAccountCellView) -> Bool {
        lhs.rendable.id == rhs.rendable.id
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            switch rendable.icon {
            case let .url(url):
                CoinLogoImageViewRepresentable(
                    size: iconSize,
                    args: .manual(preferredImage: nil, url: url, key: "", wrapped: rendable.wrapped)
                )
                .frame(width: iconSize, height: iconSize)
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