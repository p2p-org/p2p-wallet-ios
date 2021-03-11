//
//  ProfileVCBase.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation

class ProfileVCBase: BaseVStackVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    override var padding: UIEdgeInsets {.init(all: 20)}
    var dataDidChange: Bool {false}
    
    lazy var navigationBar: WLNavigationBar = {
        let navigationBar = WLNavigationBar(backgroundColor: .textWhite)
        navigationBar.backButton
            .onTap(self, action: #selector(back))
        return navigationBar
    }()
    
    override func setUp() {
        super.setUp()
        navigationBar.titleLabel.text = title
        view.backgroundColor = .f6f6f8
        
        view.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        scrollView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        scrollView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 10)
    }
    
    override func back() {
        if dataDidChange {
            showAlert(title: L10n.leaveThisPage, message: L10n.youHaveUnsavedChangesThatWillBeLostIfYouDecideToLeave, buttonTitles: [L10n.stay, L10n.leave], highlightedButtonIndex: 0) { (index) in
                if index == 1 {
                    super.back()
                }
            }
        } else {
            super.back()
        }
    }
}
