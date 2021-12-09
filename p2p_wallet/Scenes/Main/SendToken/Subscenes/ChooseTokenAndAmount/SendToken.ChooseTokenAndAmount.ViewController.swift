//
//  SendToken.ChooseTokenAndAmount.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import UIKit

extension SendToken.ChooseTokenAndAmount {
    class ViewController: SendToken.BaseViewController {
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseTokenAndAmountViewModelType
        private let scenesFactory: SendTokenScenesFactory
        
        // MARK: - Properties
        
        // MARK: - Initializer
        init(
            viewModel: SendTokenChooseTokenAndAmountViewModelType,
            scenesFactory: SendTokenScenesFactory
        ) {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            navigationBar.titleLabel.text = L10n.send
            navigationBar.backButton.onTap(self, action: #selector(_back))
            navigationBar.rightItems.addArrangedSubview(
                UILabel(text: L10n.next.uppercaseFirst, textSize: 17, textColor: .h5887ff)
                    .onTap(self, action: #selector(buttonNextDidTouch))
            )
            
            let rootView = RootView(viewModel: viewModel)
            view.addSubview(rootView)
            rootView.autoPinEdge(.top, to: .bottom, of: navigationBar)
            rootView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .chooseWallet:
                let vc = scenesFactory.makeChooseWalletViewController(
                    customFilter: { $0.amount > 0},
                    showOtherWallets: false,
                    handler: viewModel
                )
                present(vc, animated: true, completion: nil)
            case .backToConfirmation:
                navigationController?.popToViewController(ofClass: SendToken.ConfirmViewController.self, animated: true)
            }
        }
        
        @objc private func _back() {
            if viewModel.showAfterConfirmation {
                back()
            } else {
                viewModel.cancelSending()
            }
        }
        
        @objc private func buttonNextDidTouch() {
            viewModel.save()
            viewModel.navigateNext()
        }
    }
}
