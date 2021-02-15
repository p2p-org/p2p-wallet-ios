//
//  SwapTokenViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/02/2021.
//

import Foundation
import UIKit
import SwiftUI
import Action

class SwapTokenViewController: WLModalWrapperVC {
    let viewModel: SwapTokenViewModel
    init(viewModel: SwapTokenViewModel) {
        self.viewModel = viewModel
        let vc = _SwapTokenViewController(viewModel: viewModel)
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
    var transactionVC: ProcessTransactionVC!
    
    // MARK: - Initializer
    init(viewModel: SwapTokenViewModel)
    {
        self.viewModel = viewModel
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
                    let vc = ChooseWalletVC()
                    vc.completion = {wallet in
                        let wallet = self.viewModel.wallets.first(where: {$0.pubkey == wallet.pubkey})
                        self.viewModel.sourceWallet.accept(wallet)
//                        self.sourceWalletView.amountTextField.becomeFirstResponder()
                        vc.back()
                    }
                    self.presentCustomModal(vc: vc, title: L10n.selectWallet)
                case .chooseDestinationWallet:
                    let vc = ChooseWalletVC(customFilter: {_ in true})
                    vc.completion = {wallet in
                        let wallet = self.viewModel.wallets.first(where: {$0.pubkey == wallet.pubkey})
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
                case .sendTransaction:
                    self.transactionVC = self.presentProcessTransactionVC()
                case .processTransaction(signature: let signature):
                    self.showProcessingTransaction(signature: signature)
                case .transactionError(let error):
                    self.transactionVC.dismiss(animated: true) {
                        self.showError(error)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    private func showProcessingTransaction(signature: String) {
        transactionVC.signature = signature
        transactionVC.viewInExplorerButton.rx.action = CocoaAction {
            self.transactionVC.dismiss(animated: true) {
                let pc = self.presentingViewController
                self.back()
                pc?.showWebsite(url: "https://explorer.solana.com/tx/" + signature)
            }
            
            return .just(())
        }
        transactionVC.goBackToWalletButton.rx.action = CocoaAction {
            self.transactionVC.dismiss(animated: true) {
                self.back()
            }
            return .just(())
        }
    }
}

//@available(iOS 13, *)
//struct SwapTokenViewController_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            UIViewControllerPreview {
//                SwapTokenViewController()
//            }
//            .previewDevice("iPhone SE (2nd generation)")
//        }
//    }
//}
