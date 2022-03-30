//
//  ReserveName.ViewController.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 26.11.2021.
//

import Foundation
import UIKit

extension ReserveName {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: ReserveNameViewModelType

        // MARK: - Properties

        private lazy var rootView = RootView(viewModel: viewModel)

        // MARK: - Methods

        init(viewModel: ReserveNameViewModelType) {
            self.viewModel = viewModel
            super.init()
            navigationItem.title = L10n.reserveP2PUsername

            if viewModel.kind == .reserveCreateWalletPart {
                let rightButton = UIBarButtonItem(
                    title: L10n.skip.capitalized,
                    style: .plain,
                    target: self,
                    action: #selector(skip)
                )
                rightButton.setTitleTextAttributes([.foregroundColor: UIColor.h5887ff], for: .normal)
                navigationItem.rightBarButtonItem = rightButton
            }
        }

        override func loadView() {
            view = rootView
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            rootView.startTyping()
        }

        override func bind() {
            super.bind()
            viewModel.isLoadingDriver
                .drive(onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.view.showIndetermineHud()
                    } else {
                        self?.view.hideHud()
                    }
                })
                .disposed(by: disposeBag)

            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .back:
                navigationController?.popViewController(animated: true)
            case .termsOfUse:
                let vc = WLMarkdownVC(
                    title: L10n.termsOfUse.uppercaseFirst,
                    bundledMarkdownTxtFileName: "Terms_of_service"
                )
                present(vc, interactiveDismissalType: .standard, completion: nil)
            case .privacyPolicy:
                let vc = WLMarkdownVC(
                    title: L10n.privacyPolicy.uppercaseFirst,
                    bundledMarkdownTxtFileName: "Privacy_policy"
                )
                present(vc, interactiveDismissalType: .standard, completion: nil)
            case let .skipAlert(completion):
                showSkipAlert(completion: completion)
            case .none:
                break
            }
        }

        private func showSkipAlert(completion: @escaping (Bool) -> Void) {
            showAlert(
                title: L10n.proceedWithoutAUsername,
                message:
                L10n.anytimeYouWantYouCanEasilyReserveAUsernameByGoingToTheSettings,
                buttonTitles: [L10n.cancel.uppercaseFirst, L10n.proceed.uppercaseFirst],
                highlightedButtonIndex: 1,
                destroingIndex: 0,
                completion: { choose in
                    completion(choose == 1)
                }
            )
        }

        @objc func skip() {
            viewModel.skipButtonPressed()
        }
    }
}
