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

protocol SendTokenScenesFactory {
    func makeChooseWalletVC(customFilter: ((Wallet) -> Bool)?) -> ChooseWalletVC
    func makeProcessTransactionVC() -> ProcessTransactionVC
}

class SendTokenViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: SendTokenViewModel
    let scenesFactory: SendTokenScenesFactory
    var transactionVC: ProcessTransactionVC!
    
    // MARK: - Subviews
    
    // MARK: - Initializer
    init(viewModel: SendTokenViewModel, scenesFactory: SendTokenScenesFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func loadView() {
        view = SendTokenRootView(viewModel: viewModel)
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
                case .chooseWallet:
                    let vc = self.scenesFactory.makeChooseWalletVC(customFilter: nil)
                    vc.completion = {wallet in
                        guard let wallet = self.viewModel.walletsVM.data.first(where: {$0.pubkey == wallet.pubkey}) else {return}
                        vc.back()
                        self.viewModel.currentWallet.accept(wallet)
                    }
                    self.presentCustomModal(vc: vc, title: L10n.selectWallet)
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
                    self.transactionVC = self.scenesFactory.makeProcessTransactionVC()
                    self.present(self.transactionVC, animated: true, completion: nil)
                case .processTransaction(let signature):
                    self.showProcessingTransaction(signature: signature)
                case .transactionError(let error):
                    self.transactionVC.dismiss(animated: true) {
                        if (error as? SolanaSDK.Error) == SolanaSDK.Error.other("The address is not valid"),
                           let symbol = self.viewModel.currentWallet.value?.symbol
                        {
                            self.showAlert(
                                title: L10n.error.uppercaseFirst,
                                message:
                                    L10n.theWalletAddressIsNotValidItMustBeAWalletAddress(symbol),
                                buttonTitles: [L10n.ok]
                            )
                        } else {
                            self.showError(error)
                        }
                        
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
