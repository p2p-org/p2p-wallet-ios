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
    func makeChooseWalletVC(customFilter: ((Wallet) -> Bool)?) -> ChooseWalletVC
    func makeSwapChooseDestinationWalletVC(customFilter: ((Wallet) -> Bool)?) -> SwapChooseDestinationWalletViewController
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
            .subscribe(onNext: {
                switch $0 {
                case .chooseSourceWallet:
                    let vc = self.scenesFactory.makeChooseWalletVC(customFilter: nil)
                    vc.completion = {wallet in
                        let wallet = self.viewModel.wallets.first(where: {$0.pubkey == wallet.pubkey})
                        self.viewModel.sourceWallet.accept(wallet)
//                        self.sourceWalletView.amountTextField.becomeFirstResponder()
                        vc.back()
                    }
                    self.presentCustomModal(vc: vc, title: L10n.selectWallet)
                case .chooseDestinationWallet:
                    let vc = self.scenesFactory.makeSwapChooseDestinationWalletVC
                    {
                        let sourceWalletPubkey = self.viewModel.sourceWallet.value?.pubkey
                        let sourceWalletMint = self.viewModel.sourceWallet.value?.mintAddress
                        return $0.pubkey != sourceWalletPubkey &&
                            self.viewModel.pools.value?.matchedPool(sourceMint: sourceWalletMint, destinationMint: $0.mintAddress) != nil
                    }
                    vc.completion = {wallet in
                        self.viewModel.destinationWallet.accept(wallet)
//                        self.destination.amountTextField.becomeFirstResponder()
                        vc.back()
                    }
                    self.presentCustomModal(vc: vc, title: L10n.selectWallet)
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
                }
            })
            .disposed(by: disposeBag)
    }
}
