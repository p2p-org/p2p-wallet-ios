//
//  SwapSlippageSettingsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/01/2021.
//

import Foundation

class SwapSlippageSettingsVC: WLModalVC {
    override init() {
        super.init()
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        stackView.addArrangedSubviews([
            UILabel(text: L10n.slippageSettings, textSize: 17, weight: .semibold)
                .padding(.init(x: 20, y: 20))
        ])
    }
}

extension SwapSlippageSettingsVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return FlexibleHeightPresentationController(position: .bottom, presentedViewController: presented, presenting: presenting)
    }
}
