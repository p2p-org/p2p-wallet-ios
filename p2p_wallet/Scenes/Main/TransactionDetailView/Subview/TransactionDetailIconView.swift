import KeyAppUI
import Kingfisher
import SolanaSwift
import SwiftUI

struct TransactionDetailIconView: View {
    private let size: CGFloat = 64
    private let defaultBackground: some View = Circle().fill(Color(Asset.Colors.snow.color))

    let icon: TransactionDetailIcon

    var body: some View {
        Group {
            switch icon {
            case let .icon(image):
                RoundedRectangle(cornerRadius: size / 2)
                    .fill(Color(Asset.Colors.rain.color))
                    .overlay(
                        Image(uiImage: image)
                            .renderingMode(.template)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    )
            case let .single(url):
                KFImage
                    .url(url)
                    .setProcessor(
                        DownsamplingImageProcessor(size: .init(width: size * 2, height: size * 2))
                            |> RoundCornerImageProcessor(cornerRadius: size)
                    )
                    .resizable()
                    .diskCacheExpiration(.days(7))
                    .fade(duration: 0.25)
                    .background(defaultBackground)
            case let .double(from, to):
                ZStack(alignment: .center) {
                    KFImage
                        .url(from)
                        .setProcessor(
                            DownsamplingImageProcessor(size: .init(width: size * 2, height: size * 2))
                                |> RoundCornerImageProcessor(cornerRadius: size)
                        )
                        .resizable()
                        .diskCacheExpiration(.days(7))
                        .fade(duration: 0.25)
                        .frame(width: size, height: size)
                        .background(defaultBackground)
                        .offset(x: -size / 4)

                    KFImage
                        .url(to)
                        .setProcessor(
                            DownsamplingImageProcessor(size: .init(width: size * 2, height: size * 2))
                                |> RoundCornerImageProcessor(cornerRadius: size)
                        )
                        .resizable()
                        .diskCacheExpiration(.days(7))
                        .fade(duration: 0.25)
                        .frame(width: size, height: size)
                        .background(defaultBackground)
                        .offset(x: size / 4)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct DetailTransactionIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TransactionDetailIconView(icon: .icon(.transactionCloseAccount))
            TransactionDetailIconView(icon: .single(URL(string: TokenMetadata.nativeSolana.logoURI!)!))
            TransactionDetailIconView(icon: .double(
                URL(string: TokenMetadata.nativeSolana.logoURI!)!,
                URL(string: TokenMetadata.renBTC.logoURI!)!
            ))
        }
    }
}
