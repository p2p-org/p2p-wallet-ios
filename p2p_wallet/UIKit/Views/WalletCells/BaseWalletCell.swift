//
// Created by Giang Long Tran on 16.02.2022.
//

import BEPureLayout
import BECollectionView
import RxSwift
import RxCocoa

class BaseWalletCell: BECompositionView {
    private let leadingActions: UIView?
    private let trailingActions: UIView?
    
    private var iconRef = BERef<CoinLogoImageView>()
    private var coinNameRef = BERef<UILabel>()
    private var exchangePriceRef = BERef<UILabel>()
    private var amountRef = BERef<UILabel>()
    private var amountInFiatRef = BERef<UILabel>()
    private var contentRef = BERef<UIView>()
    public var swipeableCellRef = BERef<SwipeableCell>()
    
    init(leadingActions: UIView, trailingActions: UIView) {
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
                .padding(.init(x: 0, y: 12))
                .backgroundColor(color: .background)
                .roundCorners([.layerMaxXMinYCorner, .layerMaxXMaxYCorner], radius: 4),
            trailingActions: trailingActions
        )
            .bind(swipeableCellRef)
            .frame(height: 63)
    }
    
    private func content() -> UIView {
        BEHStack {
            // Icon
            CoinLogoImageView(size: 32)
                .bind(iconRef)
                .centered(.vertical)
            
            UIView(width: 12)
            
            // Title
            BEVStack {
                UILabel(text: "<Coin name>")
                    .bind(coinNameRef)
                UIView(height: 6)
                UILabel(text: "<Exchange price>", textSize: 13, weight: .medium, textColor: .secondaryLabel)
                    .bind(exchangePriceRef)
            }
            UIView.spacer
            
            // Trailing
            BEVStack(alignment: .trailing) {
                UILabel(text: "<Amount>")
                    .bind(amountRef)
                UIView(height: 6)
                UILabel(text: "<Amount in fiat>", textSize: 13, weight: .medium, textColor: .secondaryLabel)
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
            coinNameRef.view?.text = item.name
        }
        amountRef.view?.text = "\(item.amount.toString(maximumFractionDigits: 9)) \(item.token.symbol)"
        
        if let exchange = item.price?.value?.toString(maximumFractionDigits: 2) {
            exchangePriceRef.view?.isHidden = false
            exchangePriceRef.view?.text = "\(Defaults.fiat.symbol) \(exchange)"
        } else {
            exchangePriceRef.view?.isHidden = true
        }
        
        amountInFiatRef.view?.text = "\(Defaults.fiat.symbol) \(item.amountInCurrentFiat.toString(maximumFractionDigits: 2))"
    }
    
    func showLoading() {
        contentRef.view?.hideLoader()
        contentRef.view?.showLoader(customGradientColor: .defaultLoaderGradientColors)
    }
    
    func hideLoading() {
        contentRef.view?.hideLoader()
    }
}
