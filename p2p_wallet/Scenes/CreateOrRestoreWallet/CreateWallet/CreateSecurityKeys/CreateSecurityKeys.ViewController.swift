//
//  CreateSecurityKeysViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import Combine
import Foundation
import UIKit

extension CreateSecurityKeys {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: CreateSecurityKeysViewModelType
        private var subscriptions = [AnyCancellable]()

        // MARK: - Initializer

        init(viewModel: CreateSecurityKeysViewModelType) {
            self.viewModel = viewModel
            super.init()
            navigationItem.title = L10n.yourSecurityKey
        }

        // MARK: - Methods

        override func loadView() {
            view = RootView(viewModel: viewModel)
        }

        override func bind() {
            super.bind()
            viewModel.showTermsAndConditionsSignal
                .sink { [weak self] in
                    let vc = WLMarkdownVC(
                        title: L10n.termsOfUse.uppercaseFirst,
                        bundledMarkdownTxtFileName: "Terms_of_service"
                    )
                    self?.present(vc, interactiveDismissalType: .standard, completion: nil)
                }
                .store(in: &subscriptions)

            viewModel.showPhotoLibraryUnavailableSignal
                .sink { [weak self] in
                    guard let self = self else { return }
                    PhotoLibraryAlertPresenter().present(on: self)
                }
                .store(in: &subscriptions)

            viewModel.errorSignal
                .sink { [weak self] error in
                    self?.showAlert(title: L10n.error.uppercaseFirst, message: error)
                }
                .store(in: &subscriptions)
        }
    }
}
