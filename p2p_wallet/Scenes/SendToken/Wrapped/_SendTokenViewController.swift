//
//  _SendTokenViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/02/2021.
//

import Foundation
import UIKit
import SwiftUI

class _SendTokenViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: _SendTokenViewModel
    
    // MARK: - Subviews
    
    // MARK: - Initializer
    init(viewModel: _SendTokenViewModel)
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func loadView() {
        view = _SendTokenRootView(viewModel: viewModel)
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
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
}
