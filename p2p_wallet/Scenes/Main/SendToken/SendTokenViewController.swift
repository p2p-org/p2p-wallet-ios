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
}

class SendTokenViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: SendTokenViewModel
    let scenesFactory: SendTokenScenesFactory
    
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
                case .processTransaction:
                    let vc = ProcessTransactionViewController(viewModel: self.viewModel.processTransactionViewModel)
                    self.present(vc, animated: true, completion: nil)
                }
            })
            .disposed(by: disposeBag)
    }
}
