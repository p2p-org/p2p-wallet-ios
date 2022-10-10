//
//  EnterSeedInfo.ViewController.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 18.11.2021.
//

import Combine
import Foundation
import UIKit

extension EnterSeedInfo {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: EnterSeedInfoViewModelType
        private var subscriptions = [AnyCancellable]()

        // MARK: - Properties

        // MARK: - Methods

        init(viewModel: EnterSeedInfoViewModelType) {
            self.viewModel = viewModel
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
            case .done:
                dismiss(animated: true)
            case .none:
                break
            }
        }
    }
}
