//
//  Authentication.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//

import BEPureLayout
import Foundation
import LocalAuthentication
import UIKit

extension Authentication {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: AuthenticationViewModelType

        // MARK: - Properties

        override var title: String? { didSet { pincodeVC.title = title } }
        var isIgnorable: Bool = false { didSet { pincodeVC.isIgnorable = isIgnorable } }
        var useBiometry: Bool = true { didSet { pincodeVC.useBiometry = useBiometry } }
        let extraAction: ExtraAction

        // MARK: - Callbacks

        var onSuccess: ((_ resetPassword: Bool) -> Void)?
        var onCancel: (() -> Void)?

        // MARK: - Subscenes

        private lazy var pincodeVC: PinCodeViewController = {
            let pincodeVC = PinCodeViewController(viewModel: viewModel, extraAction: extraAction)
            pincodeVC.onSuccess = { [weak self] in
                self?.authenticationDidComplete(resetPassword: false)
            }
            pincodeVC.onCancel = { [weak self] in
                self?.cancel()
            }
            pincodeVC.didTapResetPincodeWithASeedPhraseButton = { [weak self] in
                self?.viewModel.showResetPincodeWithASeedPhrase()
            }
            return pincodeVC
        }()

        // MARK: - Initializer

        init(viewModel: AuthenticationViewModelType, extraAction: ExtraAction = .none) {
            self.viewModel = viewModel
            self.extraAction = extraAction
            super.init()
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()
            add(child: pincodeVC)
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
            case .resetPincodeWithASeedPhrase:
                let vm = ResetPinCodeWithSeedPhrases.ViewModel()
                let vc = ResetPinCodeWithSeedPhrases.ViewController(viewModel: vm)

                vc.modalPresentationStyle = .pageSheet
                vc.completion = { [weak self] in
                    self?.viewModel.setBlockedTime(nil)
                    self?.authenticationDidComplete(resetPassword: true)
                }
                present(vc, animated: true, completion: nil)
            case let .signOutAlert(onLogout):
                showAlert(
                    title: L10n.areYouSureYouWantToSignOut,
                    message: L10n.ifYouHaveNoBackupYouMayNeverBeAbleToAccessThisAccount,
                    buttonTitles: [L10n.signOut, L10n.stay],
                    highlightedButtonIndex: 1,
                    destroingIndex: 0
                ) { [weak self] index in
                    guard index == 0 else { return }
                    self?.dismiss(animated: true, completion: { onLogout() })
                }
            }
        }

        // MARK: - Actions

        @objc private func cancel() {
            onCancel?()
            dismiss(animated: true, completion: nil)
        }

        private func authenticationDidComplete(resetPassword: Bool) {
            onSuccess?(resetPassword)
            dismiss(animated: true, completion: nil)
        }
    }
}
