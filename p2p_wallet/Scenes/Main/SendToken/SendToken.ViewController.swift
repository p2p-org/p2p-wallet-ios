//
//  SendViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/06/2021.
//

import Foundation
import UIKit
import RxSwift

protocol SendTokenScenesFactory {
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool) -> ChooseWalletViewController
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController
}

extension SendToken {
    class ViewController: WLIndicatorModalVC {
        
        // MARK: - Properties
        let viewModel: ViewModel
        let scenesFactory: SendTokenScenesFactory
        lazy var rootView = RootView(viewModel: viewModel)
        
        // MARK: - Initializer
        init(viewModel: ViewModel, scenesFactory: SendTokenScenesFactory)
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
            viewModel.output.navigationScene
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene) {
            switch scene {
            case .chooseWallet:
                let vc = self.scenesFactory.makeChooseWalletViewController(customFilter: {$0.amount > 0}, showOtherWallets: false)
                vc.completion = { [weak self, weak vc] wallet in
                    self?.viewModel.analyticsManager.log(
                        event: .sendSelectTokenClick(tokenTicker: wallet.token.symbol)
                    )
                    self?.viewModel.input.walletPubkey.onNext(wallet.pubkey)
                    vc?.back()
                }
                self.present(vc, animated: true, completion: nil)
            case .chooseAddress:
                break
            case .scanQrCode:
                let vc = QrCodeScannerVC()
                vc.callback = { code in
                    if NSRegularExpression.publicKey.matches(code) {
                        self.viewModel.input.address.onNext(code)
                        return true
                    }
                    return false
                }
                vc.modalPresentationStyle = .custom
                self.present(vc, animated: true, completion: nil)
            case .processTransaction(let request, let transactionType):
                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
                self.present(vc, animated: true, completion: nil)
            case .feeInfo:
                let vc = FreeTransactionInfoVC(position: .bottom)
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
}
