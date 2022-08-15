//
//  VerifySecurityKeys.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.11.21.
//

import Combine
import Foundation
import UIKit

extension VerifySecurityKeys {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: VerifySecurityKeysViewModelType
        private var subscriptions = [AnyCancellable]()

        // MARK: - Properties

        // MARK: - Methods

        init(viewModel: VerifySecurityKeysViewModelType) {
            self.viewModel = viewModel
            viewModel.generate()
            super.init()
            navigationItem.title = L10n.verifyYourSecurityKey
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
            case .onMistake:
                showAlert(
                    title: L10n.theseWordsDonTMatch,
                    message: L10n.TheWordsInYourSecurityKeyNeedToBeSelectedInTheRightOrder
                        .alternativelyYouCanMakeAnICloudBackup,
                    actions: [
                        UIAlertAction(title: L10n.goBack, style: .destructive) { [weak self] _ in
                            self?.viewModel.back()
                        },
                        UIAlertAction(title: L10n.tryAgain, style: .default) { [weak self] _ in
                            self?.viewModel.generate()
                        },
                    ]
                )
            default:
                break
            }
        }
    }
}
