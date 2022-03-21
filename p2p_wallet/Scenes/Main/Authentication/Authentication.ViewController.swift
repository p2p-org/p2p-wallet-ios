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

        // MARK: - Callbacks

        var onSuccess: (() -> Void)?
        var onCancel: (() -> Void)?

        // MARK: - Subscenes

        private lazy var pincodeVC: PinCodeViewController = {
            let pincodeVC = PinCodeViewController(viewModel: viewModel)
            pincodeVC.onSuccess = { [weak self] in
                self?.authenticationDidComplete()
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

        init(viewModel: AuthenticationViewModelType) {
            self.viewModel = viewModel
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
                vc.completion = { [weak self] in
                    self?.viewModel.setBlockedTime(nil)
                    self?.authenticationDidComplete()
                }
                present(vc, animated: true, completion: nil)
            }
        }

        // MARK: - Actions

        @objc private func cancel() {
            onCancel?()
            dismiss(animated: true, completion: nil)
        }

        private func authenticationDidComplete() {
            onSuccess?()
            dismiss(animated: true, completion: nil)
        }
    }
}
