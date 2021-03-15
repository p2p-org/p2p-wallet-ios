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

class SendTokenViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: SendTokenViewModel
    let scenesFactory: SendTokenScenesFactory
    lazy var rootView = SendTokenRootView(viewModel: viewModel)
    
    // MARK: - Subviews
    
    // MARK: - Initializer
    init(viewModel: SendTokenViewModel, scenesFactory: SendTokenScenesFactory)
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
                UILabel(text: L10n.send, textSize: 17, weight: .semibold)
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
            .subscribe(onNext: {[unowned self] in self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: SendTokenNavigatableScene) {
        switch scene {
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
    }
}
