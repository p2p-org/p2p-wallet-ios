//
//  TokenSettingsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import UIKit

class TokenSettingsViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: TokenSettingsViewModel
    lazy var navigationBar: WLNavigationBar = {
        let navigationBar = WLNavigationBar(backgroundColor: .textWhite)
        navigationBar.backButton
            .onTap(self, action: #selector(back))
        navigationBar.titleLabel.text = L10n.walletSettings
        return navigationBar
    }()
    
    // MARK: - Initializer
    init(viewModel: TokenSettingsViewModel)
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        containerView.backgroundColor = .f6f6f8
        
        containerView.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        let rootView = TokenSettingsRootView(viewModel: viewModel)
        containerView.addSubview(rootView)
        rootView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        rootView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 10)
    }
    
    override func bind() {
        super.bind()
    }
}
