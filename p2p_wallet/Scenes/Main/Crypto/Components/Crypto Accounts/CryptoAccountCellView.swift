import PnLService
import Repository
import Resolver
import SkeletonUI
import SwiftUI

struct CryptoAccountCellView: View, Equatable {
    // MARK: - Properties

    let iconSize: CGFloat = 50
    let rendable: any RenderableAccount
    let showPnL: Bool

    let onTap: (() -> Void)?
    let onButtonTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            iconView
            mainInfoView
            detailView
        }
        .contentShape(Rectangle())
        .if(rendable.onTapEnable) { view in
            view.onTapGesture {
                onTap?()
            }
        }
    }

    // MARK: - ViewBuilders

    @ViewBuilder private var iconView: some View {
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
    }

    @ViewBuilder private var mainInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rendable.title)
                .font(uiFont: .font(of: .text2))
                .foregroundColor(Color(.night))
            Text(rendable.subtitle)
                .font(uiFont: .font(of: .label1))
                .foregroundColor(Color(.mountain))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var detailView: some View {
        switch rendable.detail {
        case let .text(text):
            if showPnL,
               let solanaAccount = rendable as? RenderableSolanaAccount
            {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(text)
                        .font(uiFont: .font(of: .text3, weight: .semibold))
                        .foregroundColor(Color(.night))

                    pnlView(
                        mint: solanaAccount.account.mintAddress
                    )
                }
            } else {
                Text(text)
                    .font(uiFont: .font(of: .text3, weight: .semibold))
                    .foregroundColor(Color(.night))
            }
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

    // MARK: - ViewBuilders

    @ViewBuilder private func pnlView(mint: String) -> some View {
        RepositoryView(
            repository: Resolver.resolve(
                PnLRepository.self
            )
        ) { _ in
            Rectangle()
                .skeleton(with: true, size: .init(width: 30, height: 16))
        } errorView: { _, pnl in
            // ignore error
            pnlTextView(pnl: pnl, mint: mint)
        } content: { pnl in
            pnlTextView(pnl: pnl, mint: mint)
        }
        .frame(height: 16)
    }

    @ViewBuilder private func pnlTextView(
        pnl: PnLModel?,
        mint: String
    ) -> some View {
        if let pnl = pnl?.pnlByMint[mint]?.percent {
            Text("\(pnl)%")
                .font(uiFont: .font(of: .label1))
                .foregroundColor(Color(.mountain))
        }
    }

    // MARK: - Equatable

    static func == (lhs: CryptoAccountCellView, rhs: CryptoAccountCellView) -> Bool {
        lhs.rendable.id == rhs.rendable.id &&
            lhs.rendable.detail == rhs.rendable.detail &&
            lhs.rendable.title == rhs.rendable.title &&
            lhs.rendable.subtitle == rhs.rendable.subtitle &&
            rhs.rendable.tags == rhs.rendable.tags
    }
}
