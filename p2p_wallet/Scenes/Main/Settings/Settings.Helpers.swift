//
//  Settings.Helpers.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import Foundation

extension Settings {
    class BaseViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected var viewModel: SettingsViewModelType
        
        // MARK: - Subviews
        lazy var stackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
            navigationBar
        }
        
        lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(backgroundColor: .contentBackground)
            navigationBar.backButton
                .onTap(self, action: #selector(back))
            return navigationBar
        }()
        
        override func setUp() {
            super.setUp()
            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
        }
    }
}
