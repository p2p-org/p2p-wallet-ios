//
//  SwapToken.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/06/2021.
//

import Foundation
import UIKit
import RxSwift

protocol SwapTokenScenesFactory {
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool) -> ChooseWalletViewController
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController
}

extension SwapToken {
    class ViewController: WLIndicatorModalVC {
        
        // MARK: - Properties
        let viewModel: ViewModel
        let scenesFactory: SwapTokenScenesFactory
        
        lazy var rootView = RootView(viewModel: viewModel)
        
        // MARK: - Initializer
        init(viewModel: ViewModel,
             scenesFactory: SwapTokenScenesFactory)
        {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill, arrangedSubviews: [
                    UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
                        .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12),
                    UILabel(text: L10n.swap, textSize: 17, weight: .semibold),
                    UIImageView(width: 36, height: 36, image: .slippageSettings, tintColor: .iconSecondary)
                        .onTap(viewModel, action: #selector(ViewModel.chooseSlippage))
                ])
                    .padding(.init(all: 20)),
                UIView.defaultSeparator(),
                rootView
            ])
            
            containerView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
        }
        
        override func bind() {
            super.bind()
            viewModel.output.navigationScene
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            viewModel.output.isLoading
                .drive(onNext: {[weak self] isLoading in
                    if isLoading {
                        self?.showIndetermineHud(nil)
                    } else {
                        self?.hideHud()
                    }
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .chooseSourceWallet:
                let vc = scenesFactory.makeChooseWalletViewController(customFilter: {$0.amount > 0}, showOtherWallets: false)
                vc.completion = {[weak self, weak vc] wallet in
                    self?.viewModel.analyticsManager.log(event: .swapTokenASelectClick(tokenTicker: wallet.token.symbol))
                    self?.viewModel.input.sourceWallet.accept(wallet)
                    vc?.back()
                }
                self.present(vc, animated: true, completion: nil)
            case .chooseDestinationWallet(let validMints, let sourceWalletPubkey):
                
                let vc = scenesFactory.makeChooseWalletViewController(customFilter: {
                    return $0.pubkey != sourceWalletPubkey &&
                        validMints.contains($0.mintAddress)
                }, showOtherWallets: true)
                
                vc.completion = {[weak self, weak vc] wallet in
                    self?.viewModel.analyticsManager.log(event: .swapTokenBSelectClick(tokenTicker: wallet.token.symbol))
                    self?.viewModel.input.destinationWallet.accept(wallet)
                    vc?.back()
                }
                self.present(vc, animated: true, completion: nil)
            case .chooseSlippage:
                let vc = SwapSlippageSettingsVC(slippage: Defaults.slippage * 100)
                vc.completion = {[weak self] slippage in
                    Defaults.slippage = slippage / 100
                    self?.viewModel.input.slippage.accept(slippage / 100)
                }
                self.present(vc, animated: true, completion: nil)
            case .processTransaction(let request, let transactionType):
                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
                self.present(vc, animated: true, completion: nil)
            default:
                break
            }
        }
    }
}
