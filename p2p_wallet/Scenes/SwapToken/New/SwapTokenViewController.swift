//
//  SwapTokenViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/02/2021.
//

import Foundation
import UIKit
import SwiftUI

class SwapTokenViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: SwapTokenViewModel
    
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
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
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
