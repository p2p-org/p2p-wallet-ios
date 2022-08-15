//
//  SendToken.ChooseTokenAndAmount.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Combine
import Foundation
import UIKit

extension SendToken.ChooseTokenAndAmount {
    final class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: SendTokenChooseTokenAndAmountViewModelType
        private var viewAppeared: Bool = false
        private var subscriptions = [AnyCancellable]()

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

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if !viewAppeared {
                customView.amountTextField.becomeFirstResponder()
                viewAppeared = true
            }
        }

        func clearForm() {
            viewModel.clearForm.send()
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
            viewModel.navigatableScenePublisher
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)

            viewModel.errorPublisher
                .map { $0 == nil }
                .assign(to: \.isEnabled, on: nextButton)
                .store(in: &subscriptions)
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
                        viewModel.wallet?.token.symbol ?? "",
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
