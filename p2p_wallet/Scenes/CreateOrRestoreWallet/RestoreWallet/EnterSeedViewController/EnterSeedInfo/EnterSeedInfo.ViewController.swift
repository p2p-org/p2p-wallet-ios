//
//  EnterSeedInfo.ViewController.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 18.11.2021.
//

import Foundation
import UIKit

extension EnterSeedInfo {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: EnterSeedInfoViewModelType

        // MARK: - Properties

        // MARK: - Methods

        init(viewModel: EnterSeedInfoViewModelType) {
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
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .done:
                dismiss(animated: true)
            case .none:
                break
            }
        }
    }
}
