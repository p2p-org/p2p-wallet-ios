//
//  CreateSecurityKeys.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import UIKit
import TagListView
import RxSwift
import Action

extension CreateSecurityKeys {
    class NewRootView: ScrollableVStackRootView {
        // MARK: - Dependencies
        @Injected private var viewModel: CreateSecurityKeysViewModelType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton
                .onTap(self, action: #selector(back))
            navigationBar.titleLabel.text = L10n.yourSecurityKey
            return navigationBar
        }()
        
        // MARK: - Initializers
        init() {
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
        }
        
        // MARK: - Layout
        private func layout() {
            addSubview(navigationBar)
            navigationBar.titleLabel.text = L10n.createANewWallet
            navigationBar.autoPinEdge(toSuperviewSafeArea: .top)
            navigationBar.autoPinEdge(toSuperviewEdge: .leading)
            navigationBar.autoPinEdge(toSuperviewEdge: .trailing)
        }
        
        private func bind() {
        }
        
        // MARK: - Actions
        @objc func createPhrases() {
            viewModel.createPhrases()
        }
        
        @objc func toggleCheckbox() {
            viewModel.toggleCheckbox()
        }
        
        @objc func saveToICloud() {
            viewModel.saveToICloud()
        }
        
        @objc func goNext() {
            viewModel.next()
        }
        
        @objc func back() {
            viewModel.back()
        }
    }
}
