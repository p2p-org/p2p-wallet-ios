//
//  ReceiveToken.ReceiveSolanaView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

extension ReceiveToken {
    class ReceiveSolanaView: BECompositionView {
        private let disposeBag = DisposeBag()
        
        private let viewModel: ReceiveTokenSolanaViewModelType
        
        private var qrView: UIView!
        
        init(viewModel: ReceiveTokenSolanaViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                
                QrCodeCard(
                    username: viewModel.username,
                    pubKey: viewModel.pubkey,
                    token: viewModel.tokenWallet?.token
                )
                    .onCopy { [unowned self] _ in
                        self.viewModel.copyAction()
                    }.onShare { image in
                        self.viewModel.shareAction(image: image)
                    }.onSave { image in
                        self.viewModel.saveAction(image: image)
                    }
                
                // Explore button
                if viewModel.hasExplorerButton {
                    ExplorerButton(title: L10n.viewInExplorer("Solana"))
                        .onTap { [weak self] in self?.viewModel.showSOLAddressInExplorer() }
                }
            }
        }
    }
}
