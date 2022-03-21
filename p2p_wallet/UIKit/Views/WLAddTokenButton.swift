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
    lazy var titleLabel = UILabel(text: L10n.addToken, weight: .semibold, textColor: .white, textAlignment: .center)

    lazy var feeLabel: LazyLabel<Double> = {
        let label = LazyLabel<Double>(textSize: 13, textColor: UIColor.white.withAlphaComponent(0.5), textAlignment: .center)
        label.isUserInteractionEnabled = false
        return label
    }()

    var isActive: Bool = true {
        didSet {
            backgroundColor = isActive ? .h5887ff : .a3a5baStatic
            isUserInteractionEnabled = isActive
        }
    }

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
            titleLabel,
            feeLabel,
        ])
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 16, y: 10))
    }

    func setUp(with item: Wallet, showLoading: Bool = true) {
        if item.isBeingCreated == true {
            if showLoading {
                setUp(loading: true)
                titleLabel.text = L10n.addingTokenToYourWallet
            }

            feeLabel.isHidden = true
        } else {
            if showLoading {
                setUp(loading: false)
                titleLabel.text = L10n.addToken
            }
            feeLabel.isHidden = false
        }
    }

    func setUp(feeSubject: LazySubject<Double>) {
        if feeLabel.subject == nil {
            feeLabel
                .subscribed(to: feeSubject) {
                    L10n.willCost + " " + $0.toString(maximumFractionDigits: 9) + " SOL"
                }
                .disposed(by: disposeBag)
            feeLabel.isUserInteractionEnabled = false
        }
    }
}

extension Reactive where Base: WLAddTokenButton {
    /// Reactive wrapper for `setTitle(_:for:)`
    var isActive: Binder<Bool> {
        Binder(base) { button, isActive in
            button.isActive = isActive
        }
    }
}
