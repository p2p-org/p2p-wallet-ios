//
// Created by Giang Long Tran on 16.02.2022.
//

import BECollectionView
import BEPureLayout
import RxCocoa
import RxSwift
import SolanaSwift

class BaseWalletCell: BECompositionView {
    private let leadingActions: UIView?
    private let trailingActions: UIView?

    private var iconRef = BERef<CoinLogoImageView>()
    private var coinNameRef = BERef<UILabel>()
    private var amountRef = BERef<UILabel>()
    private var amountInFiatRef = BERef<UILabel>()
    private var contentRef = BERef<UIView>()
    var swipeableCellRef = BERef<SwipeableCell>()

    init(leadingActions: UIView? = nil, trailingActions: UIView? = nil) {
        self.leadingActions = leadingActions
        self.trailingActions = trailingActions
        super.init()
    }

    override func build() -> UIView {
        SwipeableCell(
            leadingActions: leadingActions,
            content: content()
                .bind(contentRef)
                .padding(.init(x: 18, y: 0))
                .withTag(1)
                .padding(.init(x: 0, y: 8))
                .backgroundColor(color: .background)
                .lightShadow()
                .roundCorners(
                    [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMinXMaxYCorner],
                    radius: 4
                ),
            trailingActions: trailingActions
        )
            .bind(swipeableCellRef)
            .frame(height: 64)
    }

    private func content() -> UIView {
        BEHStack {
            // Icon
            CoinLogoImageView(size: 48, cornerRadius: 16)
                .bind(iconRef)
                .centered(.vertical)

            UIView(width: 12)

            // Title
            BEVStack {
                UILabel(text: "<Coin name>", textSize: 16)
                    .bind(coinNameRef)
                UIView(height: 8)
                UILabel(text: "<Amount>", textSize: 12, weight: .medium, textColor: .secondaryLabel)
                    .bind(amountRef)
            }
            UIView.spacer

            // Trailing
            BEVStack(alignment: .trailing) {
                UILabel(text: "<Amount in fiat>", textSize: 17, weight: .semibold)
                    .bind(amountInFiatRef)
            }
        }
    }

    func prepareForReuse() {
        swipeableCellRef.view?.centralize(animated: false)
        iconRef.view?.tokenIcon.cancelPreviousTask()
        iconRef.view?.tokenIcon.image = nil
    }

    func setUp(with item: AnyHashable?) {
        guard let item = item as? Wallet else { return }

        iconRef.view?.setUp(wallet: item)
        if item.name.isEmpty {
            coinNameRef.view?.text = item.mintAddress.prefix(4) + "..." + item.mintAddress.suffix(4)
        } else {
            coinNameRef.view?.text = item.token.name
        }
        amountRef.view?.text = "\(item.amount.toString(maximumFractionDigits: 9)) \(item.token.symbol)"
        amountInFiatRef.view?
            .text = "\(Defaults.fiat.symbol) \(item.amountInCurrentFiat.toString(maximumFractionDigits: 2))"
    }

    func showLoading() {
        contentRef.view?.hideLoader()
        contentRef.view?.showLoader(customGradientColor: .defaultLoaderGradientColors)
    }

    func hideLoading() {
        contentRef.view?.hideLoader()
    }
}
