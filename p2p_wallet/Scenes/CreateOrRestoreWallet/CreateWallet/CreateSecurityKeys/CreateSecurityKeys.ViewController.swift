//
//  CreateSecurityKeysViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import Foundation
import UIKit

extension CreateSecurityKeys {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Dependencies

        private let viewModel: CreateSecurityKeysViewModelType

        // MARK: - Initializer

        init(viewModel: CreateSecurityKeysViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func loadView() {
            view = RootView(viewModel: viewModel)
        }

        override func bind() {
            super.bind()
            viewModel.showTermsAndConditionsSignal
                .emit(onNext: { [weak self] in
                    let vc = WLMarkdownVC(
                        title: L10n.termsOfUse.uppercaseFirst,
                        bundledMarkdownTxtFileName: "Terms_of_service"
                    )
                    self?.present(vc, interactiveDismissalType: .standard, completion: nil)
                })
                .disposed(by: disposeBag)

            viewModel.showPhotoLibraryUnavailableSignal
                .emit(onNext: { [weak self] in
                    guard let self = self else { return }
                    PhotoLibraryAlertPresenter().present(on: self)
                })
                .disposed(by: disposeBag)

            viewModel.errorSignal
                .emit(onNext: { [weak self] error in
                    self?.showAlert(title: L10n.error.uppercaseFirst, message: error)
                })
                .disposed(by: disposeBag)
        }
    }
}
