//
//  WCVHeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import Action

class WCVFirstSectionHeaderView: SectionHeaderView, LoadableView {
    lazy var priceLabel = UILabel(text: "$120,00", textSize: 36, weight: .semibold, textAlignment: .center)
    lazy var priceChangeLabel = UILabel(text: "+ 0,16 US$ (0,01%) 24 hrs", textSize: 15, textColor: .secondary, numberOfLines: 0, textAlignment: .center)
    
    lazy var sendButton = createButton(title: L10n.send)
        .onTap(self, action: #selector(buttonSendDidTouch))
    lazy var receiveButton = createButton(title: L10n.receive)
        .onTap(self, action: #selector(buttonReceiveDidTouch))
    lazy var swapButton = createButton(title: L10n.swap)
        .onTap(self, action: #selector(buttonSwapDidTouch))
    
    var sendAction: CocoaAction?
    var receiveAction: CocoaAction?
    var swapAction: CocoaAction?
    
    var loadingViews: [UIView] { [priceLabel, priceChangeLabel, sendButton.superview!, headerLabel] }
    
    override func commonInit() {
        super.commonInit()
        let buttonsView: UIView = {
            let view = UIView(forAutoLayout: ())
            view.layer.cornerRadius = 16
            view.layer.masksToBounds = true
            let buttonsStackView = UIStackView(axis: .horizontal, spacing: 2, alignment: .fill, distribution: .fillEqually)
            buttonsStackView.addArrangedSubviews([sendButton, receiveButton, swapButton])
            view.addSubview(buttonsStackView)
            buttonsStackView.autoPinEdgesToSuperviewEdges()
            return view
        }()
        
        let spacer1 = UIView.spacer
        stackView.insertArrangedSubview(spacer1, at: 0)
        stackView.insertArrangedSubview(priceLabel, at: 1)
        stackView.insertArrangedSubview(priceChangeLabel, at: 2)
        stackView.insertArrangedSubview(buttonsView, at: 3)
        
        stackView.setCustomSpacing(5, after: priceLabel)
        stackView.setCustomSpacing(30, after: priceChangeLabel)
        stackView.setCustomSpacing(30, after: buttonsView)
    }
    
    func setUp(state: FetcherState<[Wallet]>) {
        switch state {
        case .initializing:
            priceLabel.text = ""
            priceChangeLabel.text = ""
            hideLoading()
        case .loading:
            priceLabel.text = "Loading..."
            priceChangeLabel.text = "loading..."
            showLoading()
        case .loaded(let wallets):
            let equityValue = wallets.reduce(0) { (result, wallet) -> Double in
                result + (wallet.amount ?? 0) * (PricesManager.bonfida.solPrice?.value ?? 0)
            }
            priceLabel.text = "\(equityValue.currencyValueFormatted(maximumFractionDigits: 9)) US$"
            priceChangeLabel.text = "\(PricesManager.bonfida.solPrice?.change24h?.value.currencyValueFormatted() ?? "") US$ (\((PricesManager.bonfida.solPrice?.change24h?.percentage * 100).currencyValueFormatted(maximumFractionDigits: 2)) %) 24 hrs"
            hideLoading()
        case .error(let error):
            debugPrint(error)
            priceLabel.text = L10n.error.uppercaseFirst
            hideLoading()
        }
    }
    
    // MARK: - Helpers
    func createButton(title: String) -> UIView {
        let view = UIView(height: 56, backgroundColor: .textBlack)
        let label = UILabel(text: title, textSize: 15.adaptiveWidth, weight: .semibold, textColor: .textWhite, numberOfLines: 0, textAlignment: .center)
        view.addSubview(label)
        label.autoPinEdge(toSuperviewEdge: .top)
        label.autoPinEdge(toSuperviewEdge: .bottom)
        label.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
        label.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
        return view
    }
    
    // MARK: - Actions
    @objc func buttonSendDidTouch() {
        sendAction?.execute()
    }
    
    @objc func buttonReceiveDidTouch() {
        receiveAction?.execute()
    }
    
    @objc func buttonSwapDidTouch() {
        swapAction?.execute()
    }
}
