//
//  EnterSeed.ViewController.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.11.2021.
//

import Resolver
import UIKit
import RxSwift

extension EnterSeed {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Dependencies
        private let viewModel: EnterSeedViewModelType
        
        // MARK: - Properties
        
        // MARK: - Methods
        init(viewModel: EnterSeedViewModelType) {
            self.viewModel = viewModel
        }

        override func loadView() {
            view = RootView(viewModel: viewModel)
        }
        
        override func setUp() {
            super.setUp()
        }

        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in
                    self?.navigate(to: $0)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .none:
                break
            case .info:
                let vc = EnterSeedInfo.ViewController(viewModel: Resolver.resolve())
                present(vc, animated: true)
            case .back:
                navigationController?.popViewController(animated: true)
            case let .success(words):
                let viewModel = DerivableAccounts.ViewModel(phrases: words)
                let vc = DerivableAccounts.ViewController(viewModel: viewModel)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
