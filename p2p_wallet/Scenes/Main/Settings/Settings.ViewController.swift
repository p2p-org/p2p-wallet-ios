//
//  Settings.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import Foundation
import UIKit

extension Settings {
    class ViewController: BaseViewController {
        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var rootView = RootView()
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            stackView.addArrangedSubview(
                rootView.padding(.init(x: 20, y: 0))
            )
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            viewModel.logoutAlertSignal
                .emit(onNext: { [weak self] in
                    self?.showAlert(title: L10n.logout, message: L10n.doYouReallyWantToLogout, buttonTitles: ["OK", L10n.cancel], highlightedButtonIndex: 1) { [weak self] (index) in
                        guard index == 0 else {return}
                        self?.dismiss(animated: true, completion: { [weak self] in
                            self?.viewModel.logout()
                        })
                    }
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
//            switch scene {
//            case .detail:
//                break
//            default:
//                break
//            }
        }
    }
}
