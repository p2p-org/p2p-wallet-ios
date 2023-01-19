//
//  DAppContainer.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.21.
//

import Foundation
import UIKit

extension DAppContainer {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: DAppContainerViewModelType

        init(viewModel: DAppContainerViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Properties

        // MARK: - Methods

        override func loadView() {
            view = RootView(viewModel: viewModel)
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
            case .detail:
//                let vc = Detail.ViewController()
//                present(vc, completion: nil)
                break
            }
        }
    }
}
