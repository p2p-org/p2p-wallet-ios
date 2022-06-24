//
//  RestoreWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import BEPureLayout
import Foundation
import Resolver
import UIKit

extension RestoreWallet {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: RestoreWalletViewModelType

        // MARK: - Subviews

        private lazy var iCloudRestoreButton = WLStepButton.main(
            image: .appleLogo,
            text: L10n.restoreUsingICloud
        )
            .onTap(self, action: #selector(restoreFromICloud))

        private lazy var restoreManuallyButton = WLStepButton.sub(
            text: L10n.restoreManually
        )
            .onTap(self, action: #selector(restoreManually))

        // MARK: - Initializer

        init(viewModel: RestoreWalletViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()
            // pattern background view
            let patternView = UIView.introPatternView()
            view.addSubview(patternView)
            patternView.autoPinEdgesToSuperviewEdges()

            // navigation bar
            navigationItem.title = L10n.iAlreadyHaveAWallet.uppercaseFirst

            // content
            let stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
                UIView.ilustrationView(
                    image: .introImportAWallet,
                    title: L10n.importAWallet,
                    description: L10n.ICloudRestoreIsForReturningUsers.pastingTheSecurityKeyManuallyIsForEveryone
                )
                    .padding(.init(x: 20, y: 0))
                iCloudRestoreButton.padding(.init(x: 20, y: 0))
                restoreManuallyButton.padding(.init(x: 20, y: 0))
            }

            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            stackView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 20)
        }

        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(with: self) { $0.navigate(to: $1) }
                .disposed(by: disposeBag)

            viewModel.isLoadingDriver
                .drive(onNext: {
                    $0 ? UIApplication.shared.showIndetermineHud() : UIApplication.shared.hideHud()
                })
                .disposed(by: disposeBag)

            viewModel.errorSignal
                .emit(with: self) { $0.showAlert(title: L10n.error.uppercaseFirst, message: $1) }
                .disposed(by: disposeBag)

            viewModel.isRestorableUsingIcloud.map { !$0 }.drive(iCloudRestoreButton.rx.isHidden)
                .disposed(by: disposeBag)
        }

        override func present(
            _ viewControllerToPresent: UIViewController,
            animated flag: Bool,
            completion: (() -> Void)? = nil
        ) {
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        }

        // MARK: - Navigation

        private func navigate(to scene: RestoreWallet.NavigatableScene?) {
            guard let scene = scene else { return }

            switch scene {
            case .enterPhrases:
                let vm = EnterSeed.ViewModel()
                let vc = EnterSeed.ViewController(viewModel: vm, accountRestorationHandler: viewModel)
                navigationController?.pushViewController(vc, animated: true)
            case .restoreFromICloud:
                let vc = RestoreICloud.ViewController(viewModel: viewModel)
                navigationController?.pushViewController(vc, animated: true)
            case let .derivableAccounts(phrases):
                let viewModel = DerivableAccounts.ViewModel(phrases: phrases, handler: viewModel)
                let vc = DerivableAccounts.ViewController(viewModel: viewModel)
                navigationController?.pushViewController(vc, animated: true)
            case let .reserveName(owner):
                let viewModel = ReserveName.ViewModel(
                    kind: .reserveCreateWalletPart,
                    owner: owner,
                    reserveNameHandler: viewModel,
                    checkBeforeReserving: false
                )
                let viewController = ReserveName.ViewController(viewModel: viewModel)
                navigationController?.pushViewController(viewController, animated: true)
            }
        }

        // MARK: - Actions

        @objc func restoreFromICloud() {
            viewModel.restoreFromICloud()
        }

        @objc func restoreManually() {
            viewModel.restoreManually()
        }
    }
}
