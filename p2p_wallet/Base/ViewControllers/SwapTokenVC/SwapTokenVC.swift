//
//  SwapTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation

class SwapTokenVC: BaseVStackVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .normal(backgroundColor: .vcBackground) }
    override var padding: UIEdgeInsets { UIEdgeInsets(top: 44, left: 16, bottom: 0, right: 16) }
    
    lazy var fromWalletView = SwapTokenItemView(forAutoLayout: ())
    lazy var toWalletView = SwapTokenItemView(forAutoLayout: ())
    
    lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 22, image: .reverseButton)
        .onTap(self, action: #selector(buttonReverseDidTouch))
    
    lazy var swapButton = WLButton.stepButton(type: .main, label: L10n.swapNow)
        .onTap(self, action: #selector(buttonSwapDidTouch))
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        title = L10n.swap
        
        scrollView.contentView.backgroundColor = .textWhite
        scrollView.contentView.layer.cornerRadius = 16
        scrollView.contentView.layer.masksToBounds = true
        
        stackView.constraintToSuperviewWithAttribute(.top)?.constant = 20
        stackView.constraintToSuperviewWithAttribute(.bottom)?.constant = -20
        
        let reverseView: UIView = {
            let view = UIView(forAutoLayout: ())
            let separator = UIView.separator(height: 2, color: .vcBackground)
            view.addSubview(separator)
            separator.autoPinEdge(toSuperviewEdge: .leading)
            separator.autoPinEdge(toSuperviewEdge: .trailing)
            separator.autoAlignAxis(toSuperviewAxis: .horizontal)
            
            view.addSubview(reverseButton)
            reverseButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20), excludingEdge: .leading)
            
            return view
        }()
        
        stackView.addArrangedSubviews(
            [
                UILabel(text: L10n.from, weight: .medium).padding(UIEdgeInsets(x: 16, y: 0)),
                fromWalletView.padding(UIEdgeInsets(x: 16, y: 0)),
                reverseView,
                UILabel(text: L10n.to, weight: .medium).padding(UIEdgeInsets(x: 16, y: 0)),
                toWalletView.padding(UIEdgeInsets(x: 16, y: 0)),
                swapButton.padding(UIEdgeInsets(x: 16, y: 0))
            ]
        )
        
        stackView.setCustomSpacing(35, after: toWalletView.wrapper!)
        
        fromWalletView.amountTextField.delegate = self
        toWalletView.amountTextField.delegate = self
    }
    
    // MARK: - Actions
    @objc func buttonReverseDidTouch() {
        
    }
    
    @objc func buttonSwapDidTouch() {
        
    }
}

extension SwapTokenVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
