//
//  SwapTokenSettings.ViewController.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

import Combine
import Foundation
import UIKit

extension SwapTokenSettings {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: NewSwapTokenSettingsViewModelType
        private var subscriptions = [AnyCancellable]()

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
            viewModel.navigatableScenePublisher
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)
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
