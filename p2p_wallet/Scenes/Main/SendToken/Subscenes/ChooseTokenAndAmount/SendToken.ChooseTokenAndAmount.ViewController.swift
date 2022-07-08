//
//  SendToken.ChooseTokenAndAmount.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import UIKit

extension SendToken.ChooseTokenAndAmount {
    final class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: SendTokenChooseTokenAndAmountViewModelType

        // MARK: - Properties

        var customView: RootView {
            guard let customView = view as? RootView else {
                preconditionFailure("A custom view should be of type \(RootView.self)")
            }
            return customView
        }

        private lazy var nextButton: UIBarButtonItem = {
            let nextButton = UIBarButtonItem(
                title: L10n.next.uppercaseFirst,
                style: .plain,
                target: self,
                action: #selector(buttonNextDidTouch)
            )
            return nextButton
        }()

        // MARK: - Initializer

        init(
            viewModel: SendTokenChooseTokenAndAmountViewModelType,
            hidesBottomBarWhenPushed: Bool
        ) {
            self.viewModel = viewModel
            super.init()
            self.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            view.endEditing(true)
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()

            view.onTap { [weak view] in
                view?.endEditing(true)
            }

            navigationItem.title = L10n.send
            navigationItem.rightBarButtonItem = nextButton
            navigationItem.setHidesBackButton(!viewModel.canGoBack, animated: true)
        }

        override func loadView() {
            super.loadView()
            view = RootView(viewModel: viewModel)
        }

        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)

            viewModel.errorDriver
                .map { $0 == nil }
                .drive(nextButton.rx.isEnabled)
                .disposed(by: disposeBag)

            rx.viewDidAppear
                .take(1)
                .mapToVoid()
                .subscribe(onNext: { [weak self] in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        self?.customView.amountTextField.becomeFirstResponder()
                    }
                })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
            case .chooseWallet:
                let vm = ChooseWallet.ViewModel(selectedWallet: nil, handler: viewModel, showOtherWallets: false)
                vm.customFilter = { $0.amount > 0 }
                let vc = ChooseWallet.ViewController(
                    title: nil,
                    viewModel: vm
                )
                present(vc, animated: true)
            case .backToConfirmation:
                navigationController?.popToViewController(ofClass: SendToken.ConfirmViewController.self, animated: true)
            case .invalidTokenForSelectedNetworkAlert:
                showAlert(
                    title: L10n.changeTheToken,
                    message: L10n.ifTheTokenIsChangedToTheAddressFieldMustBeFilledInWithA(
                        viewModel.getSelectedWallet()?.token.symbol ?? "",
                        L10n.compatibleAddress(L10n.solana)
                    ),
                    buttonTitles: [L10n.discard, L10n.change],
                    highlightedButtonIndex: 1,
                    destroingIndex: 0
                ) { [weak self] selectedIndex in
                    guard selectedIndex == 1 else { return }
                    self?.viewModel.save()
                    self?.viewModel.navigateNext()
                }
            }
        }

        @objc private func buttonNextDidTouch() {
            if viewModel.isTokenValidForSelectedNetwork() {
                viewModel.save()
                viewModel.navigateNext()
            }
        }
    }
}
