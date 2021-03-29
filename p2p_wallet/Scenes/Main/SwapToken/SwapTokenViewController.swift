//
//  SwapTokenViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/02/2021.
//

import Foundation
import UIKit
import Action

protocol SwapScenesFactory {
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool) -> ChooseWalletViewController
}

class SwapTokenViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: SwapTokenViewModel
    let scenesFactory: SwapScenesFactory
    
    lazy var rootView = SwapTokenRootView(viewModel: viewModel)
    
    // MARK: - Initializer
    init(viewModel: SwapTokenViewModel, scenesFactory: SwapScenesFactory)
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
                UIImageView(width: 36, height: 36, image: .slippageSettings, tintColor: .a3a5ba)
                    .onTap(viewModel, action: #selector(SwapTokenViewModel.chooseSlippage))
            ])
                .padding(.init(all: 20)),
            UIView.separator(height: 1, color: .separator),
            rootView
        ])
        
        containerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: { [unowned self] in self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: SwapTokenNavigatableScene) {
        switch scene {
        case .chooseSourceWallet:
            let vc = scenesFactory.makeChooseWalletViewController(customFilter: nil, showOtherWallets: false)
            vc.completion = {[weak self, weak vc] wallet in
                if let wallet = self?.viewModel.wallets.first(where: {$0.pubkey == wallet.pubkey}) {
                    self?.viewModel.sourceWallet.accept(wallet)
                }
                vc?.back()
            }
            self.present(vc, animated: true, completion: nil)
        case .chooseDestinationWallet:
            
            let sourceWalletPubkey = viewModel.sourceWallet.value?.pubkey
            let sourceWalletMint = viewModel.sourceWallet.value?.mintAddress
            var validDestinationMints: Set<String> = Set(viewModel.pools.value?
                .filter {$0.swapData.mintA.base58EncodedString == sourceWalletMint}
                .map {$0.swapData.mintB.base58EncodedString} ?? [])
            
            validDestinationMints = validDestinationMints.union(Set(viewModel.pools.value?
                .filter {$0.swapData.mintB.base58EncodedString == sourceWalletMint}
                .map {$0.swapData.mintA.base58EncodedString} ?? []))
            
            let vc = scenesFactory.makeChooseWalletViewController(customFilter: {
                return $0.pubkey != sourceWalletPubkey &&
                    validDestinationMints.contains($0.mintAddress)
            }, showOtherWallets: true)
            vc.completion = {[weak vc] wallet in
                vc?.dismiss(animated: true, completion: { [weak self] in
                    self?.viewModel.destinationWalletDidSelect(wallet)
                })
            }
            self.present(vc, animated: true, completion: nil)
        case .chooseSlippage:
            let vc = SwapSlippageSettingsVC(slippage: Defaults.slippage * 100)
            vc.completion = {slippage in
                Defaults.slippage = slippage / 100
                self.viewModel.slippage.accept(slippage / 100)
            }
            self.present(vc, animated: true, completion: nil)
        case .processTransaction:
            let vc = ProcessTransactionViewController(viewModel: self.viewModel.processTransactionViewModel)
            self.present(vc, animated: true, completion: nil)
        case .loading(let isLoading):
            if isLoading {
                showIndetermineHudWithMessage(nil)
            } else {
                hideHud()
            }
        }
    }
}
