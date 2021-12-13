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
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool, handler: WalletDidSelectHandler) -> ChooseWallet.ViewController
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController
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
        
        // MARK: - Methods
        init(
            viewModel: OrcaSwapV2ViewModelType,
            scenesFactory: OrcaSwapV2ScenesFactory
        ) {
            self.scenesFactory = scenesFactory
            self.viewModel = viewModel
        }

        override func loadView() {
            view = RootView(viewModel: viewModel)
        }
        
        override func setUp() {
            super.setUp()
            
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
            case .chooseSourceWallet:
                let vc = scenesFactory.makeChooseWalletViewController(
                    customFilter: { $0.amount > 0 },
                    showOtherWallets: false,
                    handler: viewModel
                )
                present(vc, animated: true, completion: nil)
            case let .chooseDestinationWallet(
                validMints: validMints,
                excludedSourceWalletPubkey: excludedSourceWalletPubkey
            ):
                let vc = scenesFactory.makeChooseWalletViewController(
                    customFilter: {
                        $0.pubkey != excludedSourceWalletPubkey &&
                            validMints.contains($0.mintAddress)
                    },
                    showOtherWallets: true,
                    handler: viewModel
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
            case .swapFees:
                let vc = OrcaSwapV2.SwapFeesViewController(viewModel: viewModel)
                present(OrcaSwapV2.SettingsNavigationController(rootViewController: vc), interactiveDismissalType: .standard)
            case let .processTransaction(
                request: request,
                transactionType: transactionType
            ):
                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
                self.present(vc, animated: true, completion: nil)
            case .back:
                navigationController?.popViewController(animated: true)
            case .none:
                break
            }
        }
    }
}
