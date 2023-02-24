//
//  SwapTokenSettings.ViewController.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

import Foundation
import UIKit
import RxSwift

extension SwapTokenSettings {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: NewSwapTokenSettingsViewModelType
        private let disposeBag = DisposeBag()

        // MARK: - Methods

        init(viewModel: NewSwapTokenSettingsViewModelType) {
            self.viewModel = viewModel
            super.init()
            navigationItem.title = L10n.swapSettings
        }

        override func loadView() {
            view = RootView(viewModel: viewModel)
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
            case .back:
                navigationController?.popViewController(animated: true)
            case .none:
                break
            }
        }
    }
}
