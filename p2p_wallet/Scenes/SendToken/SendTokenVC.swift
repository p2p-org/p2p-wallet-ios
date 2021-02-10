//
//  SendTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation
import RxSwift
import Action

class SendTokenViewController: WLModalWrapperVC {
    override var padding: UIEdgeInsets {super.padding.modifying(dLeft: .defaultPadding, dRight: .defaultPadding)}
    
    init(viewModel: _SendTokenViewModel) {
        let vc = _SendTokenViewController(viewModel: viewModel)
        super.init(wrapped: vc)
    }
    
    override func setUp() {
        super.setUp()
        addHeader(title: L10n.send, image: .walletSend)
    }
}
