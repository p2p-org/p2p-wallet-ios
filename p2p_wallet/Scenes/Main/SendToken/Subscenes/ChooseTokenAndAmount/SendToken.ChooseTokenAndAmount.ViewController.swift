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

        private var parentNavigation: UINavigationController? {
            navigationController?.parent?.navigationController
        }

        private lazy var nextButton: UIBarButtonItem = {
            let nextButton = UIBarButtonItem(
                title: L10n.next.uppercaseFirst,
                style: .plain,
                target: self,
                action: #selector(buttonNextDidTouch)
            )
            nextButton.setTitleTextAttributes([.foregroundColor: UIColor.h5887ff], for: .normal)
            return nextButton
        }()

        // MARK: - Initializer

        init(viewModel: SendTokenChooseTokenAndAmountViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()

            navigationItem.title = L10n.send
            navigationItem.rightBarButtonItem = nextButton
            if viewModel.canGoBack {
                navigationItem.leftBarButtonItem = UIBarButtonItem(
                    image: UIImage(systemName: "chevron.left"),
                    style: .plain,
                    target: self,
                    action: #selector(back)
                )
                parentNavigation?.interactivePopGestureRecognizer?.delegate = self
            }
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
                present(vc, animated: true, completion: nil)
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

        override func back() {
            parentNavigation?.popViewController(animated: true)
        }
    }
}

extension SendToken.ChooseTokenAndAmount.ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldBeRequiredToFailBy _: UIGestureRecognizer) -> Bool {
        true
    }
}
