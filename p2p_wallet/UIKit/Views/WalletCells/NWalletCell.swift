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
    
    private var icon = BERef<CoinLogoImageView>()
    private var coinName = BERef<UILabel>()
    private var exchangePrice = BERef<UILabel>()
    private var amount = BERef<UILabel>()
    private var amountInFiat = BERef<UILabel>()
    
    private var container = BERef<UIView>()
    private var swipeableCell = BERef<SwipeableCell>()
    
    private let onActionSignal = PublishRelay<Action>()
    
    override func build() -> UIView {
        SwipeableCell(
            leadingActions: BECenter { UIImageView(image: .buttonSendSmall, tintColor: .h5887ff) }
                .frame(width: 70)
                .backgroundColor(color: .ebf0fc)
                .onTap { [unowned self] in onActionSignal.accept(.send) },
            content: content()
                .bind(container)
                .padding(.init(x: 18, y: 0))
                .withTag(1)
                .padding(.init(x: 0, y: 12))
                .backgroundColor(color: .background)
                .roundCorners([.layerMaxXMinYCorner, .layerMaxXMaxYCorner], radius: 4),
            trailingActions: BECenter { UIImageView(image: .eyeHide) }
                .frame(width: 70)
                .onTap { [unowned self] in onActionSignal.accept(.visible) }
        )
            .bind(swipeableCell)
            .frame(height: 63)
    }
    
    private func content() -> UIView {
        BEHStack {
            // Icon
            CoinLogoImageView(size: 32)
                .bind(icon)
                .centered(.vertical)
            
            UIView(width: 12)
            
            // Title
            BEVStack {
                UILabel(text: "<Coin name>")
                    .bind(coinName)
                UIView(height: 6)
                UILabel(text: "<Exchange price>", textSize: 13, weight: .medium, textColor: .secondaryLabel)
                    .bind(exchangePrice)
            }
            UIView.spacer
            
            // Trailing
            BEVStack(alignment: .trailing) {
                UILabel(text: "<Amount>")
                    .bind(amount)
                UIView(height: 6)
                UILabel(text: "<Amount in fiat>", textSize: 13, weight: .medium, textColor: .secondaryLabel)
                    .bind(amountInFiat)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        swipeableCell.view?.centralize(animated: false)
        icon.view?.tokenIcon.cancelPreviousTask()
        icon.view?.tokenIcon.image = nil
    }
    
    func setUp(with item: AnyHashable?) {
        guard let item = item as? Wallet else { return }
        
        icon.view?.setUp(wallet: item)
        if item.name.isEmpty {
            coinName.view?.text = item.mintAddress.prefix(4) + "..." + item.mintAddress.suffix(4)
        } else {
            coinName.view?.text = item.name
        }
        amount.view?.text = "\(item.amount.toString(maximumFractionDigits: 9)) \(item.token.symbol)"
        
        if let exchange = item.price?.value?.toString(maximumFractionDigits: 2) {
            exchangePrice.view?.isHidden = false
            exchangePrice.view?.text = "\(Defaults.fiat.symbol) \(exchange)"
        } else {
            exchangePrice.view?.isHidden = true
        }
        
        amountInFiat.view?.text = "\(Defaults.fiat.symbol) \(item.amountInCurrentFiat)"
    }
    
    func showLoading() {
        container.view?.hideLoader()
        container.view?.showLoader(customGradientColor: .defaultLoaderGradientColors)
    }
    
    func hideLoading() {
        container.view?.hideLoader()
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
