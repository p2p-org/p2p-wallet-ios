//
//  SendTokenViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/02/2021.
//

import Foundation
import UIKit
import SwiftUI
import Action

class SendTokenViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: SendTokenViewModel
    var transactionVC: ProcessTransactionVC!
    
    // MARK: - Subviews
    
    // MARK: - Initializer
    init(viewModel: SendTokenViewModel)
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func loadView() {
        view = SendTokenRootView(viewModel: viewModel)
    }
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {
                switch $0 {
                case .chooseWallet:
                    let vc = ChooseWalletVC()
                    vc.completion = {wallet in
                        guard let wallet = WalletsVM.ofCurrentUser.data.first(where: {$0.pubkey == wallet.pubkey}) else {return}
                        vc.back()
                        self.viewModel.currentWallet.accept(wallet)
                    }
                    self.present(vc, animated: true, completion: nil)
                case .chooseAddress:
                    break
                case .scanQrCode:
                    let vc = QrCodeScannerVC()
                    vc.callback = { code in
                        if NSRegularExpression.publicKey.matches(code) {
                            self.viewModel.destinationAddressInput.accept(code)
                            return true
                        }
                        return false
                    }
                    vc.modalPresentationStyle = .custom
                    self.present(vc, animated: true, completion: nil)
                case .sendTransaction:
                    self.transactionVC = self.presentProcessTransactionVC()
                case .processTransaction(let signature):
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
                let nc = self.navigationController
                self.back()
                nc?.showWebsite(url: "https://explorer.solana.com/tx/" + signature)
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
