//
//  OrcaSwapV2.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import BEPureLayout
import Foundation
import RxSwift
import UIKit

extension OrcaSwapV2 {
    class ViewController: BEScene {
        private let settingButton = UIBarButtonItem(
            image: .settings,
            style: .plain,
            target: nil,
            action: nil
        )

        // MARK: - Dependencies

        private let viewModel: OrcaSwapV2ViewModelType

        // MARK: - Handlers

        var doneHandler: (() -> Void)?

        // MARK: - Initializer

        init(viewModel: OrcaSwapV2ViewModelType) {
            self.viewModel = viewModel
            super.init()

            navigationItem.title = L10n.swap
            settingButton.setTitleTextAttributes([.foregroundColor: UIColor.h5887ff], for: .normal)
            navigationItem.rightBarButtonItem = settingButton
        }

        // MARK: - Methods

        override func build() -> UIView {
            BESafeArea {
                RootView(viewModel: viewModel)
                    .onTap(self, action: #selector(hideKeyboard))
            }
        }

        override func bind() {
            super.bind()

            settingButton.rx.tap
                .asDriver()
                .drive(onNext: { [unowned viewModel] in
                    viewModel.openSettings()
                })
                .disposed(by: disposeBag)
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: OrcaSwapV2.NavigatableScene?) {
            switch scene {
            case .settings:
                let walletsViewModel: WalletsRepository = Resolver.resolve()
                let vm = SwapTokenSettings.ViewModel(
                    nativeWallet: walletsViewModel.nativeWallet,
                    swapViewModel: viewModel
                )

                let viewController = SwapTokenSettings.ViewController(viewModel: vm)
                show(viewController, sender: nil)
            case let .chooseSourceWallet(currentlySelectedWallet: currentlySelectedWallet):
                let vm = ChooseWallet.ViewModel(
                    selectedWallet: currentlySelectedWallet,
                    handler: viewModel,
                    showOtherWallets: false
                )
                vm.customFilter = { $0.amount > 0 }
                let vc = ChooseWallet.ViewController(
                    title: L10n.selectTheFirstToken,
                    viewModel: vm
                )
                present(vc, animated: true, completion: nil)
            case let .chooseDestinationWallet(
                currentlySelectedWallet: currentlySelectedWallet,
                validMints: validMints,
                excludedSourceWalletPubkey: excludedSourceWalletPubkey
            ):
                let vm = ChooseWallet.ViewModel(
                    selectedWallet: currentlySelectedWallet,
                    handler: viewModel,
                    showOtherWallets: true
                )
                vm.customFilter = {
                    $0.pubkey != excludedSourceWalletPubkey &&
                        validMints.contains($0.mintAddress)
                }
                let vc = ChooseWallet.ViewController(
                    title: L10n.selectTheSecondToken,
                    viewModel: vm
                )
                present(vc, animated: true, completion: nil)
            case .confirmation:
                let vm = ConfirmSwapping.ViewModel(swapViewModel: viewModel)
                let vc = ConfirmSwapping.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case let .processTransaction(transaction):
                let vm = ProcessTransaction.ViewModel(processingTransaction: transaction)
                let vc = ProcessTransaction.ViewController(viewModel: vm)
                viewModel.cleanAllFields()
                navigationController?.popToViewController(ofClass: Self.self, animated: false)
                vc.specificErrorHandler = { [weak self] error in
                    guard let self = self else { return }
                    if error.readableDescription == L10n.swapInstructionExceedsDesiredSlippageLimit {
                        self.backCompletion { [weak self] in
                            self?.viewModel.navigate(to: .settings)
                        }
                    }
                }
                show(vc, sender: nil)
            case .back:
                navigationController?.popViewController(animated: true)
            case let .info(title, description):
                showAlert(title: title, message: description)
            case .none:
                break
            }
        }
    }
}
