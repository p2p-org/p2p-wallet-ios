//
//  DAppContainer.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.21.
//

import Foundation
import UIKit

extension DAppContainer {
    class ViewController: BaseVC, TabBarNeededViewController {
        // MARK: - Dependencies
        @Injected private var viewModel: DAppContainerViewModelType
        
        init(walletsRepository: WalletsRepository, dapp: DApp) {
            super.init()
            self.viewModel.inject(walletsRepository: walletsRepository, dapp: dapp)
        }
        
        // MARK: - Properties
        
        // MARK: - Methods
        override func loadView() {
            view = RootView()
        }
        
        override func setUp() {
            super.setUp()
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
//            case .detail:
//                let vc = Detail.ViewController()
//                present(vc, completion: nil)
//                break
            }
        }
    }
}
