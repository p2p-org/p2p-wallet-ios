//
//  ReserveName.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import UIKit

extension ReserveName {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private var viewModel: ReserveNameViewModelType
        
        // MARK: - Properties
        private lazy var navigationBar = WLNavigationBar(forAutoLayout: ())
        private lazy var rootView = RootView(viewModel: viewModel)
        
        // MARK: - Initializer
        init(viewModel: ReserveNameViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            view.addSubview(navigationBar)
            navigationBar.titleLabel.text = L10n.reserveYourP2PUsername
            navigationBar.autoPinEdge(toSuperviewSafeArea: .top)
            navigationBar.autoPinEdge(toSuperviewEdge: .leading)
            navigationBar.autoPinEdge(toSuperviewEdge: .trailing)
            
            let separator = UIView.defaultSeparator()
            view.addSubview(separator)
            separator.autoPinEdge(.top, to: .bottom, of: navigationBar)
            separator.autoPinEdge(toSuperviewEdge: .leading)
            separator.autoPinEdge(toSuperviewEdge: .trailing)
            
            view.addSubview(rootView)
            rootView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            rootView.autoPinEdge(.top, to: .bottom, of: separator)
            
            navigationBar.backButton.onTap(self, action: #selector(back))
        }
        
        override func bind() {
            super.bind()
            viewModel.isPostingDriver
                .drive(onNext: {[weak self] isPosting in
                    isPosting ? self?.showIndetermineHud(): self?.hideHud()
                })
                .disposed(by: disposeBag)
        }
    }
}
