//
//  WLAddTokenButton.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation
import LazySubject
import RxSwift

class WLAddTokenButton: WLLoadingView {
    let disposeBag = DisposeBag()
    lazy var buttonAddTokenLabel = UILabel(text: L10n.addToken, weight: .semibold, textColor: .white, textAlignment: .center)
    
    lazy var feeLabel: LazyLabel<Double> = {
        let label = LazyLabel<Double>(textSize: 13, textColor: UIColor.white.withAlphaComponent(0.5), textAlignment: .center)
        label.isUserInteractionEnabled = false
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        configureForAutoLayout()
        autoSetDimension(.height, toSize: 56)
        backgroundColor = .h5887ff
        layer.cornerRadius = 12
        layer.masksToBounds = true
    }
    
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
            buttonAddTokenLabel,
            feeLabel
        ])
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 16, y: 10))
    }
    
    func setUp(with item: Wallet) {
        if item.isBeingCreated == true {
            setUp(loading: true)
            buttonAddTokenLabel.text = L10n.addingTokenToYourWallet
            feeLabel.isHidden = true
        } else {
            setUp(loading: false)
            buttonAddTokenLabel.text = L10n.addToken
            feeLabel.isHidden = false
        }
    }
    
    func setUp(feeSubject: LazySubject<Double>) {
        if feeLabel.viewModel == nil {
            feeLabel
                .subscribed(to: feeSubject) {
                    L10n.willCost + " " + $0.toString(maximumFractionDigits: 9) + " SOL"
                }
                .disposed(by: disposeBag)
            feeLabel.isUserInteractionEnabled = false
        }
        
    }
}
