//
//  SecuritySettingVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class SecuritySettingVC: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    var nextVC: UIViewController {
        fatalError("Must override")
    }
    
    lazy var stackView = UIStackView(axis: .vertical, spacing: 36, alignment: .center, distribution: .fill)
    
    lazy var buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
    
    lazy var acceptButton = WLButton.stepButton(type: .blue, label: nil)
        .onTap(self, action: #selector(buttonAcceptDidTouch))
    
    lazy var doThisLaterButton = WLButton.stepButton(type: .gray, label: L10n.doThisLater)
        .onTap(self, action: #selector(buttonDoThisLaterDidTouch))
    
    lazy var spacer1 = UIView.spacer
    lazy var spacer2 = UIView.spacer
    
    override func setUp() {
        super.setUp()
        
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets(top: 0, left: 20, bottom: 16, right: 20))
        
        stackView.addArrangedSubview(spacer1)
        stackView.addArrangedSubview(spacer2)
        stackView.addArrangedSubview(buttonStackView)
        buttonStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -40)
            .isActive = true
        
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor).isActive = true
        
        buttonStackView.addArrangedSubview(acceptButton)
        buttonStackView.addArrangedSubview(doThisLaterButton)
    }
    
    @objc func buttonDoThisLaterDidTouch() {
        next()
    }
    
    @objc func buttonAcceptDidTouch() {}
    
    func next() {
        show(nextVC, sender: nil)
    }
}
