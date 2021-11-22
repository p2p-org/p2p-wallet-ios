//
//  WalletDetail.InfoViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import UIKit

extension WalletDetail {
    class InfoViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: WalletDetailViewModelType
        
        // MARK: - Subviews
        private lazy var overviewView = InfoOverviewView(viewModel: viewModel)
        
        // MARK: - Initializers
        init(viewModel: WalletDetailViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                overviewView
                UIView.spacer
            }
            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 18, excludingEdge: .top))
        }
    }
}
