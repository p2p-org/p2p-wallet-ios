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
    
    lazy var navigationBar: WLNavigationBar = {
        let navigationBar = WLNavigationBar(backgroundColor: .contentBackground)
        navigationBar.backButton
            .onTap(self, action: #selector(back))
        return navigationBar
    }()
    
    override func setUp() {
        super.setUp()
        navigationBar.titleLabel.text = title
        view.backgroundColor = .listBackground
        
        view.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        scrollView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        scrollView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 10)
        
        scrollView.contentInset = .zero
        stackView.spacing = 1
    }
}
