//
//  PT.DetailViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import UIKit
import BEPureLayout

extension ProcessTransaction {
    final class DetailViewController: BEScene {
        private let viewModel: PTViewModelType
        
        init(viewModel: PTViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func build() -> UIView {
            BEVStack {
                WLNavigationBar()
                    .setup { navigationBar in
                        navigationBar.backButton
                            .onTap { [weak self] in
                                self?.back()
                            }
                    }
                UIView()
            }
        }
    }
}
