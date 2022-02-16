//
// Created by Giang Long Tran on 16.02.2022.
//

import BEPureLayout
import BECollectionView
import RxSwift
import RxCocoa

class NWalletCell: BECollectionCell, BECollectionViewCell {
    enum Action {
        case visible
        case send
    }
    
    private var iconRef = BERef<CoinLogoImageView>()
    private var coinNameRef = BERef<UILabel>()
    private var exchangePriceRef = BERef<UILabel>()
    private var amountRef = BERef<UILabel>()
    private var amountInFiatRef = BERef<UILabel>()
    private var contentRef = BERef<UIView>()
    private var swipeableCellRef = BERef<SwipeableCell>()
    
    private let onActionSignal = PublishRelay<Action>()
    
    override func build() -> UIView {
        SwipeableCell(
            leadingActions: BECenter { UIImageView(image: .buttonSendSmall, tintColor: .h5887ff) }
                .frame(width: 70)
                .backgroundColor(color: .ebf0fc)
                .onTap { [unowned self] in
                    onActionSignal.accept(.send)
                    swipeableCellRef.view?.centralize()
                },
            content: content()
                .bind(contentRef)
                .padding(.init(x: 18, y: 0))
                .withTag(1)
                .padding(.init(x: 0, y: 12))
                .backgroundColor(color: .background)
                .roundCorners([.layerMaxXMinYCorner, .layerMaxXMaxYCorner], radius: 4),
            trailingActions: BECenter { UIImageView(image: .eyeHide) }
                .frame(width: 70)
                .onTap { [unowned self] in
                    onActionSignal.accept(.visible)
                    swipeableCellRef.view?.centralize()
                }
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
        
        amountInFiatRef.view?.text = "\(Defaults.fiat.symbol) \(item.amountInCurrentFiat)"
    }
    
    func showLoading() {
        contentRef.view?.hideLoader()
        contentRef.view?.showLoader(customGradientColor: .defaultLoaderGradientColors)
    }
    
    func hideLoading() {
        contentRef.view?.hideLoader()
    }
}

extension NWalletCell: SwipeableDelegate {
    private class None {}
    
    var onAction: Signal<Any> {
        onActionSignal
            .map { action -> Any in action }
            .asSignal(onErrorJustReturn: None())
    }
}
