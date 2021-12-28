//
//  OrcaSwapV2.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import UIKit
import RxSwift

protocol OrcaSwapV2ScenesFactory {
    func makeChooseWalletViewController(
        title: String?,
        customFilter: ((Wallet) -> Bool)?,
        showOtherWallets: Bool,
        selectedWallet: Wallet?,
        handler: WalletDidSelectHandler
    ) -> ChooseWallet.ViewController
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController
    func makeSwapSettingsViewController(swapViewModel: OrcaSwapV2ViewModelType) -> UIViewController
}

extension OrcaSwapV2 {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Dependencies
        private let viewModel: OrcaSwapV2ViewModelType
        private let scenesFactory: OrcaSwapV2ScenesFactory

        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var navigationBar = NavigationBar(
            backHandler: { [weak viewModel] in
                viewModel?.navigate(to: .back)
            },
            settingsHandler: { [weak viewModel] in
                viewModel?.openSettings()
            }
        )
        private lazy var rootView = RootView(viewModel: viewModel)
            .onTap(self, action: #selector(hideKeyboard))
        
        // MARK: - Methods
        init(
            viewModel: OrcaSwapV2ViewModelType,
            scenesFactory: OrcaSwapV2ScenesFactory
        ) {
            self.scenesFactory = scenesFactory
            self.viewModel = viewModel
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
                let viewController = scenesFactory.makeSwapSettingsViewController(swapViewModel: viewModel)

                present(viewController, animated: true)
            case let .chooseSourceWallet(currentlySelectedWallet: currentlySelectedWallet):
                let vc = scenesFactory.makeChooseWalletViewController(
                    title: L10n.selectTheFirstToken,
                    customFilter: { $0.amount > 0 },
                    showOtherWallets: false,
                    selectedWallet: currentlySelectedWallet,
                    handler: viewModel
                )
                present(vc, animated: true, completion: nil)
            case let .chooseDestinationWallet(
                currentlySelectedWallet: currentlySelectedWallet,
                validMints: validMints,
                excludedSourceWalletPubkey: excludedSourceWalletPubkey
            ):
                let vc = scenesFactory.makeChooseWalletViewController(
                    title: L10n.selectTheSecondToken,
                    customFilter: {
                        $0.pubkey != excludedSourceWalletPubkey &&
                            validMints.contains($0.mintAddress)
                    },
                    showOtherWallets: true,
                    selectedWallet: currentlySelectedWallet,
                    handler: viewModel
                )
                present(vc, animated: true, completion: nil)
            case .confirmation:
                let vm = ConfirmSwapping.ViewModel(swapViewModel: viewModel)
                let vc = ConfirmSwapping.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case let .processTransaction(
                request: request,
                transactionType: transactionType
            ):
                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
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
