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

class SwapTokenViewController: WLModalWrapperVC {
    let viewModel: SwapTokenViewModel
    let scenesFactory: SwapScenesFactory
    init(viewModel: SwapTokenViewModel, scenesFactory: SwapScenesFactory) {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        let vc = _SwapTokenViewController(viewModel: viewModel, scenesFactory: scenesFactory)
        super.init(wrapped: vc)
    }
    
    override func setUp() {
        super.setUp()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.addArrangedSubviews([
            UIImageView(width: 24, height: 24, image: .walletSwap, tintColor: .white)
                .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12),
            UILabel(text: L10n.swap, textSize: 17, weight: .semibold),
            UIImageView(width: 36, height: 36, image: .slippageSettings, tintColor: .a3a5ba)
                .onTap(viewModel, action: #selector(SwapTokenViewModel.chooseSlippage))
        ])
        
        let separator = UIView.separator(height: 1, color: .separator)
        containerView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }
}

private class _SwapTokenViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: SwapTokenViewModel
    let scenesFactory: SwapScenesFactory
    
    // MARK: - Initializer
    init(viewModel: SwapTokenViewModel, scenesFactory: SwapScenesFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func loadView() {
        view = SwapTokenRootView(viewModel: viewModel)
    }
    
    override func setUp() {
        super.setUp()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))
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
