//
//  OrcaSwapV2.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import UIKit
import RxSwift

extension OrcaSwapV2 {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Dependencies
        private let viewModel: OrcaSwapV2ViewModelType

        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var navigationBar = NavigationBar(
            backHandler: { [weak viewModel] in
                viewModel?.navigate(to: .back)
            },
            settingsHandler: { [weak viewModel] in
                viewModel?.navigate(to: .settings)
            }
        )
        private lazy var rootView = RootView(viewModel: viewModel)
            .onTap(self, action: #selector(hideKeyboard))
        
        // MARK: - Methods
        init(viewModel: OrcaSwapV2ViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            rootView.makeFromFirstResponder()
        }

        override func setUp() {
            super.setUp()
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            
            view.addSubview(rootView)
            rootView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
            rootView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: OrcaSwapV2.NavigatableScene?) {
            switch scene {
            case .settings:
                let vc = OrcaSwapV2.SettingsViewController(viewModel: viewModel)
                let nc = OrcaSwapV2.SettingsNavigationController(rootViewController: vc)
                nc.modalPresentationStyle = .custom
                present(nc, interactiveDismissalType: .standard)
            case let .chooseSourceWallet(currentlySelectedWallet: currentlySelectedWallet):
                let vm = ChooseWallet.ViewModel(selectedWallet: currentlySelectedWallet, handler: viewModel, showOtherWallets: false)
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
                let vm = ChooseWallet.ViewModel(selectedWallet: currentlySelectedWallet, handler: viewModel, showOtherWallets: true)
                vm.customFilter = {
                    $0.pubkey != excludedSourceWalletPubkey &&
                        validMints.contains($0.mintAddress)
                }
                let vc = ChooseWallet.ViewController(
                    title: L10n.selectTheSecondToken,
                    viewModel: vm
                )
                present(vc, animated: true, completion: nil)
            case .chooseSlippage:
                let vc = OrcaSwapV2.SlippageSettingsViewController()
                vc.completion = {[weak self] slippage in
                    self?.viewModel.changeSlippage(to: slippage / 100)
                }
                present(OrcaSwapV2.SettingsNavigationController(rootViewController: vc), interactiveDismissalType: .standard)
            case let .choosePayFeeToken(tokenName):
                let vc = OrcaSwapV2.NetworkFeePayerSettingsViewController(transactionTokenName: tokenName ?? "")
                vc.completion = { [weak self] method in
                    Defaults.payingToken = method
                    self?.viewModel.changePayingToken(to: method)
                }

                present(OrcaSwapV2.SettingsNavigationController(rootViewController: vc), interactiveDismissalType: .standard)
            case .confirmation:
                let vm = ConfirmSwapping.ViewModel(swapViewModel: viewModel)
                let vc = ConfirmSwapping.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case let .processTransaction(
                request: request,
                transactionType: transactionType
            ):
                let vc = ProcessTransaction.ViewController(transactionType: transactionType, request: request)
                vc.delegate = self
                present(vc, animated: true, completion: nil)
            case .back:
                navigationController?.popViewController(animated: true)
            case .none:
                break
            }
        }
    }
}

extension OrcaSwapV2.ViewController: ProcessTransactionViewControllerDelegate {
    func processTransactionViewControllerDidComplete(_ vc: UIViewController) {
        vc.dismiss(animated: true) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
}
